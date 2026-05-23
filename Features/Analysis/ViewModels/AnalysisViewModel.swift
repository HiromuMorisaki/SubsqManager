//
//  AnalysisViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

@Observable
final class AnalysisViewModel {
    
    // MARK: - データ構造定義
    
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: Date
        let amount: Decimal
    }
    
    struct CategoryData: Identifiable {
        let id = UUID()
        let category: Category
        let amount: Decimal
    }
    
    /// カテゴリ別詳細データ
    struct CategoryDetailedData: Identifiable {
        let id = UUID()
        let category: Category
        let amount: Decimal
        let subscriptionCount: Int
        let averageSatisfaction: Double
    }
    
    /// 満足度別支出データ
    struct SatisfactionData: Identifiable {
        let id = UUID()
        let rating: Int // 1〜5
        let amount: Decimal
    }
    
    /// シミュレーション前後の比較予測データ
    struct MonthlyTrendComparisonData: Identifiable {
        let id = UUID()
        let month: Date
        let beforeAmount: Decimal
        let afterAmount: Decimal
    }
    
    // MARK: - 家計分析用ロジック
    
    /// サブスクリプション全体の平均満足度を計算する
    func averageSatisfaction(from subscriptions: [Subscription]) -> Double {
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        guard !activeSubs.isEmpty else { return 0.0 }
        let total = activeSubs.reduce(0.0) { $0 + Double($1.satisfaction) }
        return total / Double(activeSubs.count)
    }
    
    /// 無駄遣い指数を計算する（満足度2以下、または月利用0回が占める割合 0.0 〜 1.0）
    func wastageIndex(from subscriptions: [Subscription]) -> Double {
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        let totalAmount = activeSubs.reduce(Decimal.zero) { $0 + $1.ownShareMonthlyAmount }
        guard totalAmount > 0 else { return 0.0 }
        
        let wasteAmount = activeSubs.reduce(Decimal.zero) { total, sub in
            if sub.satisfaction <= 2 || sub.monthlyUsageCount == 0 {
                return total + sub.ownShareMonthlyAmount
            }
            return total
        }
        
        return NSDecimalNumber(decimal: wasteAmount).doubleValue / NSDecimalNumber(decimal: totalAmount).doubleValue
    }
    
    /// 月間無駄遣い合計金額を計算する
    func wastageAmount(from subscriptions: [Subscription]) -> Decimal {
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        return activeSubs.reduce(Decimal.zero) { total, sub in
            if sub.satisfaction <= 2 || sub.monthlyUsageCount == 0 {
                return total + sub.ownShareMonthlyAmount
            }
            return total
        }
    }
    
    /// 満足度（★1〜5）ごとの月額支出割合を計算する
    func satisfactionBreakdown(from subscriptions: [Subscription]) -> [SatisfactionData] {
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        var totals: [Int: Decimal] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for sub in activeSubs {
            let rating = sub.satisfaction
            if rating >= 1 && rating <= 5 {
                totals[rating, default: 0] += sub.ownShareMonthlyAmount
            }
        }
        
        return (1...5).map { SatisfactionData(rating: $0, amount: totals[$0] ?? 0) }
    }
    
    /// カテゴリ別の詳細内訳（支出、件数、平均満足度）を計算する
    func categoryDetailedBreakdown(from subscriptions: [Subscription]) -> [CategoryDetailedData] {
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        var totals: [Category: Decimal] = [:]
        var counts: [Category: Int] = [:]
        var satTotals: [Category: Double] = [:]
        
        for sub in activeSubs {
            totals[sub.category, default: 0] += sub.ownShareMonthlyAmount
            counts[sub.category, default: 0] += 1
            satTotals[sub.category, default: 0] += Double(sub.satisfaction)
        }
        
        return totals
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { (category, amount) in
                let count = counts[category] ?? 0
                let avgSat = count > 0 ? (satTotals[category] ?? 0.0) / Double(count) : 0.0
                return CategoryDetailedData(
                    category: category,
                    amount: amount,
                    subscriptionCount: count,
                    averageSatisfaction: avgSat
                )
            }
    }
    
    /// 今後12ヶ月間の月別支払額を計算する (既存互換用)
    func monthlyTrend(from subscriptions: [Subscription]) -> [MonthlyData] {
        var data: [MonthlyData] = []
        let calendar = Calendar.current
        let today = Date()
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        
        for monthOffset in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: monthOffset, to: today) {
                let monthStart = calendar.startOfDay(for: date)
                
                let amountForMonth = activeSubs.reduce(Decimal.zero) { total, sub in
                    if let endDate = sub.endDate, endDate < monthStart {
                        return total
                    }
                    return total + sub.ownShareMonthlyAmount
                }
                
                data.append(MonthlyData(month: date, amount: amountForMonth))
            }
        }
        
        return data
    }
    
    /// カテゴリ別の割合を計算する (既存互換用)
    func categoryBreakdown(from subscriptions: [Subscription]) -> [CategoryData] {
        var totals: [Category: Decimal] = [:]
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        
        for sub in activeSubs {
            totals[sub.category, default: 0] += sub.ownShareMonthlyAmount
        }
        
        return totals
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { CategoryData(category: $0.key, amount: $0.value) }
    }
    
    // MARK: - 固定費予測・削減シミュレーション用ロジック
    
    /// シミュレーション選択トグルを考慮した、今後12ヶ月間のBefore/Afterの支出推移予測データを計算する。
    /// 無料トライアルの期間終了（有料化）、および個別の終了予定日（endDate）を正確にタイムラインに反映。
    func monthlyTrendComparison(
        from subscriptions: [Subscription],
        excludeSatisfactionTwoOrLess: Bool,
        excludeUsageOneOrLess: Bool,
        excludeTrials: Bool
    ) -> [MonthlyTrendComparisonData] {
        var data: [MonthlyTrendComparisonData] = []
        let calendar = Calendar.current
        let today = Date()
        
        for monthOffset in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: monthOffset, to: today) else { continue }
            let monthStart = calendar.startOfDay(for: date)
            
            var beforeTotal = Decimal.zero
            var afterTotal = Decimal.zero
            
            for sub in subscriptions {
                // すでに物理的に終了日を過ぎていれば除外
                if let endDate = sub.endDate, endDate < monthStart {
                    continue
                }
                
                // 1. Before (現行予測) 金額算出
                let subBeforeAmount: Decimal
                if sub.isTrial {
                    if let trialEndDate = sub.trialEndDate {
                        if trialEndDate >= monthStart {
                            // まだその月は無料トライアル期間中
                            subBeforeAmount = 0
                        } else {
                            // トライアル期間が終了したため、有料本契約扱い
                            subBeforeAmount = sub.ownShareMonthlyAmount
                        }
                    } else {
                        subBeforeAmount = 0
                    }
                } else {
                    subBeforeAmount = sub.ownShareMonthlyAmount
                }
                
                if !sub.isExpired {
                    beforeTotal += subBeforeAmount
                }
                
                // 2. After (削減シミュレーション適用) 金額算出
                var isSimulatedCancelled = false
                
                // 条件A: 満足度2以下
                if excludeSatisfactionTwoOrLess && sub.satisfaction <= 2 {
                    isSimulatedCancelled = true
                }
                
                // 条件B: 利用頻度「ほぼ使っていない (月1回以下)」
                if excludeUsageOneOrLess && sub.monthlyUsageCount <= 1 {
                    isSimulatedCancelled = true
                }
                
                // 条件C: トライアル本契約への自動移行をしない
                if excludeTrials && sub.isTrial {
                    isSimulatedCancelled = true
                }
                
                if !isSimulatedCancelled {
                    let subAfterAmount: Decimal
                    if sub.isTrial {
                        if let trialEndDate = sub.trialEndDate {
                            if trialEndDate >= monthStart {
                                subAfterAmount = 0
                            } else {
                                subAfterAmount = sub.ownShareMonthlyAmount
                            }
                        } else {
                            subAfterAmount = 0
                        }
                    } else {
                        subAfterAmount = sub.ownShareMonthlyAmount
                    }
                    
                    if !sub.isExpired {
                        afterTotal += subAfterAmount
                    }
                }
            }
            
            data.append(MonthlyTrendComparisonData(
                month: date,
                beforeAmount: beforeTotal,
                afterAmount: afterTotal
            ))
        }
        
        return data
    }
    
    /// 現在の削減シミュレーション適用時の削減効果（月額・年額）を算出する
    func calculateSimulationSavings(
        from subscriptions: [Subscription],
        excludeSatisfactionTwoOrLess: Bool,
        excludeUsageOneOrLess: Bool,
        excludeTrials: Bool
    ) -> (monthlySavings: Decimal, yearlySavings: Decimal) {
        let activeSubs = subscriptions.filter { !$0.isExpired }
        var monthlySavings = Decimal.zero
        var yearlySavings = Decimal.zero
        
        for sub in activeSubs {
            var isSimulatedCancelled = false
            
            if excludeSatisfactionTwoOrLess && sub.satisfaction <= 2 {
                isSimulatedCancelled = true
            }
            if excludeUsageOneOrLess && sub.monthlyUsageCount <= 1 {
                isSimulatedCancelled = true
            }
            if excludeTrials && sub.isTrial {
                isSimulatedCancelled = true
            }
            
            if isSimulatedCancelled {
                // トライアル中であっても削減できた将来のコストとして換算
                monthlySavings += sub.ownShareMonthlyAmount
                yearlySavings += sub.ownShareYearlyAmount
            }
        }
        
        return (monthlySavings, yearlySavings)
    }
}
