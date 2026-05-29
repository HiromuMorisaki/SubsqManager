//
//  DashboardViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData
import SwiftUI

/// ダッシュボード画面のViewModel。
/// サブスクリプション一覧から月額合計・年額合計・次回請求情報を計算する。
///
/// ### 計算の仕組み
/// 各 Subscription は billingCycle（週額/月額/年額）を持っており、
/// BillingCycle.monthlyMultiplier / yearlyMultiplier を使って統一単位に換算する。
/// 例: 週額¥500 → 月額換算 ¥500 × (52/12) ≈ ¥2,167
@Observable
final class DashboardViewModel {

    /// 用途フィルタ
    var expenseFilter: ExpenseFilter = .all

    /// フィルタ適用後のサブスクリプションを返す
    func filteredSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        switch expenseFilter {
        case .all: return subscriptions
        case .privateOnly: return subscriptions.filter { !$0.isExpense }
        case .expenseOnly: return subscriptions.filter { $0.isExpense }
        }
    }

    /// 旧データ（isActive == false）から ReductionHistory へのマイグレーション処理を実行する。
    /// 一度だけ実行されるように UserDefaults で管理する。
    func migrateLegacyInactiveSubscriptions(using modelContext: ModelContext) {
        let key = "hasMigratedLegacyInactiveSubscriptions"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        do {
            let descriptor = FetchDescriptor<Subscription>(
                predicate: #Predicate<Subscription> { $0.isActive == false }
            )
            let legacySubs = try modelContext.fetch(descriptor)

            guard !legacySubs.isEmpty else {
                UserDefaults.standard.set(true, forKey: key)
                return
            }

            for sub in legacySubs {
                let history = ReductionHistory(
                    name: sub.name,
                    amount: sub.amount,
                    billingCycle: sub.billingCycle,
                    category: sub.category,
                    cancelledDate: sub.updatedAt,
                    iconName: sub.iconName,
                    originalMemo: sub.notes.isEmpty ? nil : sub.notes
                )
                modelContext.insert(history)
                modelContext.delete(sub)
            }

            try modelContext.save()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("Failed to migrate legacy inactive subscriptions: \(error)")
        }
    }

    /// 累計削減額（月額換算）を計算する。
    func totalReducedMonthlyAmount(_ histories: [ReductionHistory]) -> Decimal {
        histories.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
    }

    /// 累計削減額（年額換算）を計算する。
    func totalReducedYearlyAmount(_ histories: [ReductionHistory]) -> Decimal {
        histories.reduce(Decimal.zero) { $0 + $1.yearlyAmount }
    }

    /// 月額合計を計算する。
    /// 全アクティブサブスクの金額を monthlyMultiplier で月額に変換して合算。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 月額合計金額（Decimal）
    func totalMonthlyAmount(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions
            .filter { !$0.isTrial && !$0.isExpired }
            .reduce(Decimal.zero) { total, subscription in
                total + subscription.ownShareMonthlyAmount
            }
    }

    /// 年額合計を計算する。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 年額合計金額（Decimal）
    func totalYearlyAmount(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions
            .filter { !$0.isTrial && !$0.isExpired }
            .reduce(Decimal.zero) { total, subscription in
                total + subscription.ownShareYearlyAmount
            }
    }

    /// 今月実際に発生する請求予定額の合計を計算する。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 今月実際に支払う合計金額（Decimal）
    func actualBillingAmountThisMonth(_ subscriptions: [Subscription]) -> Decimal {
        let now = Date()
        var totalAmount: Decimal = 0
        
        for sub in subscriptions where !sub.isTrial && !sub.isExpired {
            let paymentDatesThisMonth = PaymentDateCalculator.paymentDates(for: sub, inMonth: now)
            let numberOfPayments = Decimal(paymentDatesThisMonth.count)
            // 実際の自己負担額（1回あたりの金額 × 自己負担割合 × 今月の支払い回数）
            let actualAmountForSub = (sub.amount * Decimal(sub.ownSharePercentage)) * numberOfPayments
            totalAmount += actualAmountForSub
        }
        
        return totalAmount
    }

    /// 次回請求が最も近いサブスクリプションを返す。
    /// nextPaymentDate が現在以降のもののうち、最も早い日付のものを選ぶ。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 次回請求が最も近いサブスク（なければnil）
    func nextUpcomingSubscription(_ subscriptions: [Subscription]) -> Subscription? {
        let now = Date()
        return subscriptions
            .filter { $0.nextPaymentDate >= now && !$0.isExpired }
            .min { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    /// 直近 of 請求予定リスト（最大5件）を返す。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 次回請求日が近い順にソートされた配列（最大5件）
    func upcomingSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        let now = Date()
        return subscriptions
            .filter { $0.nextPaymentDate >= now && !$0.isExpired }
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
            .prefix(5)
            .map { $0 }
    }

    /// カテゴリごとの月額合計金額を計算する。
    /// グラフ表示用に、金額が0より大きいカテゴリのみを抽出して返す。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: (Category, Decimal) の配列
    func monthlyAmountByCategory(_ subscriptions: [Subscription]) -> [(Category, Decimal)] {
        var totals: [Category: Decimal] = [:]
        
        for subscription in subscriptions where !subscription.isTrial && !subscription.isExpired {
            totals[subscription.category, default: 0] += subscription.ownShareMonthlyAmount
        }
        
        return totals
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value } // 金額の降順
            .map { ($0.key, $0.value) }
    }

    /// サービスごとの月額合計金額を計算する。
    /// グラフ表示用に、金額が0より大きいサービスのみを抽出して返す。
    /// 戻り値はタプルで (ID, 表示名, 金額, アイコン名, ベースカラー) を返す。
    func monthlyAmountByService(_ subscriptions: [Subscription]) -> [(id: String, name: String, amount: Decimal, iconName: String, color: Color)] {
        // 同じ名前のサブスクリプションをまとめる（複数契約している場合等）
        var totals: [String: (amount: Decimal, icon: String, color: Color)] = [:]
        
        for sub in subscriptions where !sub.isTrial && !sub.isExpired {
            if let existing = totals[sub.name] {
                totals[sub.name] = (existing.amount + sub.ownShareMonthlyAmount, existing.icon, existing.color)
            } else {
                totals[sub.name] = (sub.ownShareMonthlyAmount, sub.iconName, sub.category.color)
            }
        }
        
        return totals
            .filter { $0.value.amount > 0 }
            .map { (id: $0.key, name: $0.key, amount: $0.value.amount, iconName: $0.value.icon, color: $0.value.color) }
            .sorted { $0.amount > $1.amount } // 金額の降順
    }

    // MARK: - コスパ診断 & 削減目標

    /// コスパ診断結果の深刻度・推奨度を表す種別
    enum DiagnosisType: String, Codable, CaseIterable {
        case critical   // 🚨 要注意（解約推奨：満足度2以下、または利用回数0回）
        case warning    // ⚠️ 要検討（見直し候補：満足度3以下、かつコスト高または利用少）
        case excellence // ✨ コスパ優秀・大満足（満足度4以上でよく使っている、または満足度5）
    }

    /// コスパ診断の結果を表す構造体
    struct CostPerformanceIssue: Identifiable {
        let id = UUID()
        let subscription: Subscription
        let type: DiagnosisType
        let unitCost: Decimal // 1回あたりのコスト
        let advice: String
        
        // 既存コードとの後方互換性のためのゲッター
        var isCritical: Bool {
            type == .critical
        }
    }

    /// アクティブなサブスクリプションを診断し、警告および優秀な項目を返す
    func diagnoseCostPerformance(_ subscriptions: [Subscription]) -> [CostPerformanceIssue] {
        var issues: [CostPerformanceIssue] = []

        for sub in subscriptions where !sub.isTrial && !sub.isExpired {
            let monthlyAmount = sub.ownShareMonthlyAmount
            let usageCount = sub.monthlyUsageCount
            let satisfaction = sub.satisfaction

            // 1回あたりのコスト（0回の場合は月額全額）
            let unitCost: Decimal = usageCount > 0 ? (monthlyAmount / Decimal(usageCount)) : monthlyAmount

            // 🚨 要注意（解約推奨）: 満足度が2点以下、または月間利用回数が0回
            if satisfaction <= 2 || usageCount == 0 {
                let advice = usageCount == 0
                    ? "今月一度も利用されていません。解約することで月 \(CurrencyHelper.formatted(amount: monthlyAmount)) を完全に削減できます。"
                    : "満足度が低く、利用頻度も少ないため解約をおすすめします。解約により月 \(CurrencyHelper.formatted(amount: monthlyAmount)) の節約になります。"
                
                issues.append(CostPerformanceIssue(
                    subscription: sub,
                    type: .critical,
                    unitCost: unitCost,
                    advice: advice
                ))
            }
            // ⚠️ 見直し候補: 満足度が3点以下、かつ（1回あたりのコストが ¥1,000 以上 または 月間利用回数が 2回以下）
            else if satisfaction <= 3 && (unitCost >= 1000 || usageCount <= 2) {
                let advice = "満足度に対して1回あたりの利用コスト（\(CurrencyHelper.formatted(amount: unitCost))）が高め、もしくは利用回数が少ないです。プラン変更または解約を検討しましょう。"
                
                issues.append(CostPerformanceIssue(
                    subscription: sub,
                    type: .warning,
                    unitCost: unitCost,
                    advice: advice
                ))
            }
            // ✨ コスパ優秀・大満足: 満足度が5点満点、または満足度が4点以上かつ月間利用回数が4回以上
            else if satisfaction >= 5 || (satisfaction >= 4 && usageCount >= 4) {
                let advice = satisfaction >= 5
                    ? "満足度が最高評価です！非常にお気に入りのサービスとして、生活に素晴らしい価値をもたらしています。このまま愛用しましょう。✨"
                    : "大満足で活用されており、1回あたりのコスト（\(CurrencyHelper.formatted(amount: unitCost))）も十分に抑えられています。大変お得です！👍"
                
                issues.append(CostPerformanceIssue(
                    subscription: sub,
                    type: .excellence,
                    unitCost: unitCost,
                    advice: advice
                ))
            }
        }

        // 重要度順（要注意 -> 要検討 -> 優秀）にソートして返す
        return issues.sorted { a, b in
            let orderA: Int
            switch a.type {
            case .critical: orderA = 0
            case .warning: orderA = 1
            case .excellence: orderA = 2
            }
            
            let orderB: Int
            switch b.type {
            case .critical: orderB = 0
            case .warning: orderB = 1
            case .excellence: orderB = 2
            }
            
            return orderA < orderB
        }
    }

    /// 削減目標に対するモチベーションメッセージを取得する
    func goalMotivationMessage(progress: Double, hasGoal: Bool) -> String {
        guard hasGoal else { return "目標を設定して、固定費削減を始めましょう！🎯" }
        if progress >= 1.0 {
            return "目標達成！おめでとうございます！🎉✨"
        } else if progress >= 0.5 {
            return "素晴らしいペースです！あと少しで目標達成！🔥"
        } else {
            return "一歩ずつ削減を進めましょう！🌱"
        }
    }
}
