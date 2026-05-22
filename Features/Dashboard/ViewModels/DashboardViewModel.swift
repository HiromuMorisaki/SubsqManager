//
//  DashboardViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// ダッシュボード画面のViewModel。
/// サブスクリプション一覧から月額合計・年額合計・次回請求情報を計算する。
///
/// ### 計算の仕組み
/// 各 Subscription は billingCycle（週額/月額/年額）を持っており、
/// BillingCycle.monthlyMultiplier / yearlyMultiplier を使って統一単位に換算する。
/// 例: 週額¥500 → 月額換算 ¥500 × (52/12) ≈ ¥2,167
@Observable
final class DashboardViewModel {

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

    // MARK: - コスパ診断 & 削減目標

    /// コスパ診断の結果を表す構造体
    struct CostPerformanceIssue: Identifiable {
        let id = UUID()
        let subscription: Subscription
        let isCritical: Bool // 要注意(true) か 見直し候補(false)か
        let unitCost: Decimal // 1回あたりのコスト
        let advice: String
    }

    /// アクティブなサブスクリプションを診断し、警告に引っかかった項目を返す
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
                    isCritical: true,
                    unitCost: unitCost,
                    advice: advice
                ))
            }
            // ⚠️ 見直し候補: 満足度が3点以下、かつ（1回あたりのコストが ¥1,000 以上 または 月間利用回数が 2回以下）
            else if satisfaction <= 3 && (unitCost >= 1000 || usageCount <= 2) {
                let advice = "満足度に対して1回あたりの利用コスト（\(CurrencyHelper.formatted(amount: unitCost))）が高め、もしくは利用回数が少ないです。プラン変更または解約を検討しましょう。"
                
                issues.append(CostPerformanceIssue(
                    subscription: sub,
                    isCritical: false,
                    unitCost: unitCost,
                    advice: advice
                ))
            }
        }

        // 重要度順（要注意が先）にソートして返す
        return issues.sorted { $0.isCritical && !$1.isCritical }
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
