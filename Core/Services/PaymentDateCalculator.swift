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
        }
    }

    /// BillingCycle に対応する Calendar.Component を返す。
    private static func calendarComponent(for billingCycle: BillingCycle) -> Calendar.Component {
        switch billingCycle {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
}
