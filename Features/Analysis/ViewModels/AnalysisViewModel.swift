//
//  AnalysisViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

@Observable
final class AnalysisViewModel {
    
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
    
    /// 今後12ヶ月間の月別支払額を計算する
    func monthlyTrend(from subscriptions: [Subscription]) -> [MonthlyData] {
        var data: [MonthlyData] = []
        let calendar = Calendar.current
        let today = Date()
        
        // ざっくりとした計算: 毎月の支払い額を月額換算で一律として扱う
        let activeSubs = subscriptions.filter { !$0.isTrial && !$0.isExpired }
        let totalMonthly = activeSubs.reduce(Decimal.zero) { $0 + $1.ownShareMonthlyAmount }
        
        for monthOffset in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: monthOffset, to: today) {
                // サブスクごとに、その月で有効かどうかを判定してより正確に計算することも可能だが、
                // 今回は現在の月額換算をベースに将来も継続すると仮定する。
                // 終了日が設定されている場合は、その月を過ぎていれば除外する。
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
    
    /// カテゴリ別の割合を計算する
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
}
