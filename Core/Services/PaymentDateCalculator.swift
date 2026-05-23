//
//  PaymentDateCalculator.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// 次回請求日の計算ロジックを提供するサービス。
///
/// ### 計算アルゴリズム
/// 1. startDate が未来の場合 → startDate がそのまま次回請求日
/// 2. startDate が過去の場合 →
///    a. startDate から現在までに経過した請求間隔の回数を算出
///    b. startDate にその回数分の間隔を加算
///    c. 結果がまだ現在より前なら、もう1回分を加算
///
/// ### 月末の例外処理
/// `Calendar.date(byAdding:)` は月末を自動調整する。
/// 例: startDate=1月31日 + 1ヶ月 → 2月28日（うるう年なら29日）
///
/// **重要**: 常に元の startDate からN回分を加算する（反復加算しない）。
/// これにより「1月31日 + 2ヶ月 = 3月31日」が正しく計算される。
/// （反復だと「1月31日→2月28日→3月28日」と誤差が蓄積する）
enum PaymentDateCalculator {

    /// 現在日時以降で最も近い次回請求日を計算する。
    ///
    /// - Parameters:
    ///   - startDate: サブスクリプションの開始日
    ///   - billingCycle: 請求サイクル（週額/月額/年額）
    ///   - referenceDate: 基準日（デフォルトは現在日時。テスト時に差し替え可能）
    /// - Returns: referenceDate 以降で最も近い請求日
    static func nextPaymentDate(
        startDate: Date,
        billingCycle: BillingCycle,
        after referenceDate: Date = Date()
    ) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        
        if billingCycle == .oneTime {
            return start
        }

        let reference = calendar.startOfDay(for: referenceDate)

        // startDate が未来なら、それ自体が次回請求日
        if start >= reference {
            return start
        }

        // 経過した請求間隔の回数を算出
        let intervalsPassed = calculateIntervalsPassed(
            from: start, to: reference,
            billingCycle: billingCycle, calendar: calendar
        )

        // 加算に使う Calendar.Component を決定
        let component = calendarComponent(for: billingCycle)

        // startDate に intervalsPassed 回分を加算して候補日を算出
        guard let candidate = calendar.date(
            byAdding: component, value: intervalsPassed, to: start
        ) else {
            return start
        }

        // 月末調整等で候補日が reference より前になった場合、1間隔追加
        if candidate < reference {
            guard let next = calendar.date(
                byAdding: component, value: intervalsPassed + 1, to: start
            ) else {
                return candidate
            }
            return next
        }

        return candidate
    }

    /// 指定された月内に発生するすべての請求日を取得する。
    /// - Parameters:
    ///   - subscription: 対象 of サブスクリプション
    ///   - targetMonth: 取得対象の月（この日付が含まれる月の1日〜月末までを探索する）
    /// - Returns: 月内の請求日の配列（昇順）
    static func paymentDates(
        for subscription: Subscription,
        inMonth targetMonth: Date
    ) -> [Date] {
        let calendar = Calendar.current
        
        // targetMonth の月の初日と最終日を計算
        let components = calendar.dateComponents([.year, .month], from: targetMonth)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return []
        }
        
        if subscription.billingCycle == .oneTime {
            let paymentDay = calendar.startOfDay(for: subscription.startDate)
            if paymentDay >= startOfMonth && paymentDay <= endOfMonth {
                return [paymentDay]
            } else {
                return []
            }
        }

        var dates: [Date] = []
        var currentRef = startOfMonth
        
        // startOfMonth から順に nextPaymentDate を計算し、endOfMonth を超えるまでループ
        while true {
            let nextDate = nextPaymentDate(
                startDate: subscription.startDate,
                billingCycle: subscription.billingCycle,
                after: currentRef
            )
            
            // 算出した請求日が月の最終日より後なら探索終了
            if nextDate > endOfMonth {
                break
            }
            
            // 算出した請求日が今月内なら追加
            if nextDate >= startOfMonth {
                dates.append(nextDate)
            }
            
            // 次の基準日を「今回の請求日の翌日」に設定してループ
            guard let nextRef = calendar.date(byAdding: .day, value: 1, to: nextDate) else {
                break
            }
            currentRef = nextRef
        }
        
        return dates
    }

    // MARK: - Private ヘルパー

    /// startDate から referenceDate までに経過した請求間隔の回数を計算する。
    /// - 週額: 経過日数 ÷ 7
    /// - 月額: Calendar の月差分
    /// - 年額: Calendar の年差分
    private static func calculateIntervalsPassed(
        from start: Date, to reference: Date,
        billingCycle: BillingCycle, calendar: Calendar
    ) -> Int {
        switch billingCycle {
        case .weekly:
            // 週の差分は日数から計算する（Calendar の weekOfYear 差分は不正確なため）
            let days = calendar.dateComponents([.day], from: start, to: reference).day ?? 0
            return days / 7
        case .monthly:
            return calendar.dateComponents([.month], from: start, to: reference).month ?? 0
        case .yearly:
            return calendar.dateComponents([.year], from: start, to: reference).year ?? 0
        case .oneTime:
            return 0
        }
    }

    /// BillingCycle に対応する Calendar.Component を返す。
    private static func calendarComponent(for billingCycle: BillingCycle) -> Calendar.Component {
        switch billingCycle {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        case .oneTime: return .day
        }
    }
}
