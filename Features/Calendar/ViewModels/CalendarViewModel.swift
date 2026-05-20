//
//  CalendarViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// カレンダーのマス目に表示する日付データ
struct CalendarDate: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    /// 現在表示している月の日付かどうか（前後の月の余白部分は false）
    let isCurrentMonth: Bool
}

/// カレンダー画面のViewModel。
/// 表示月の管理、日付グリッドの生成、および選択された日付のサブスク抽出を行う。
@Observable
final class CalendarViewModel {

    /// 現在カレンダーに表示している月（デフォルトは今月）
    var currentMonth: Date = Date()

    /// カレンダーで選択されている日付（デフォルトは今日）
    var selectedDate: Date = Date()

    private let calendar = Calendar.current

    // MARK: - 月の移動

    /// 1ヶ月前に移動
    func moveToPreviousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    /// 1ヶ月後に移動
    func moveToNextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    // MARK: - 日付生成

    /// `currentMonth` のカレンダーに表示する日付（CalendarDate）の配列を生成する。
    /// 7カラムのグリッドで表示するため、月初の前と月末の後ろの余白（前後の月の日付）も埋める。
    func generateCalendarDates() -> [CalendarDate] {
        var dates: [CalendarDate] = []

        // 当月の1日を取得
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }

        // 当月の日数と、1日の曜日（1:日曜日 〜 7:土曜日）を取得
        guard let monthRange = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        // 1日の前の余白（前月の日付）を生成
        // 例: 1日が水曜日(4)なら、日・月・火の3日分前月を埋める
        let prefixDays = firstWeekday - 1
        if prefixDays > 0 {
            for i in (1...prefixDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                    dates.append(CalendarDate(date: date, isCurrentMonth: false))
                }
            }
        }

        // 当月の日付を生成
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(CalendarDate(date: date, isCurrentMonth: true))
            }
        }

        // 月末の後の余白（次月の日付）を生成し、全体が7の倍数になるようにする
        let suffixDays = 7 - (dates.count % 7)
        if suffixDays < 7 {
            guard let lastDate = dates.last?.date else { return dates }
            for i in 1...suffixDays {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDate) {
                    dates.append(CalendarDate(date: date, isCurrentMonth: false))
                }
            }
        }

        return dates
    }

    // MARK: - サブスクデータの抽出

    /// 特定の日付に支払いが発生するサブスクリプションを抽出する。
    /// 支払日計算ロジック（PaymentDateCalculator）を使用して月内の全支払日を算出し、
    /// 指定された日付と一致するかどうかを判定する。
    func subscriptions(for date: Date, from allSubscriptions: [Subscription]) -> [Subscription] {
        var result: [Subscription] = []

        for sub in allSubscriptions {
            // 対象の月内で発生する全支払日を取得
            let paymentDates = PaymentDateCalculator.paymentDates(for: sub, inMonth: date)
            
            // 指定された日付（年・月・日）と一致する支払日があるかチェック
            let hasPaymentOnDate = paymentDates.contains { pDate in
                calendar.isDate(pDate, inSameDayAs: date)
            }
            
            if hasPaymentOnDate {
                result.append(sub)
            }
        }

        return result
    }

    /// 抽出されたサブスクリプションの合計金額（月額換算ではなく、その日の実際の支払い額）
    func totalAmount(for subscriptions: [Subscription]) -> Decimal {
        subscriptions.reduce(Decimal.zero) { $0 + $1.amount }
    }
}
