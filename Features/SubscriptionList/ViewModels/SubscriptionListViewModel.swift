//
//  SubscriptionListViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// サブスク一覧画面のビジネスロジックを担当するViewModel。
///
/// ### @Observable について
/// iOS 17で導入された Observation フレームワークのマクロ。
/// 従来の ObservableObject + @Published の代替として使用する。
/// - ObservableObject: クラス内のどの @Published が変わっても全Viewが再描画される
/// - @Observable: 実際に参照しているプロパティが変わった時だけ再描画される（高効率）
///
/// ### SwiftData の @Query との役割分担
/// - データ取得: View側の @Query が自動的にDBを監視・取得する
/// - ビジネスロジック: ViewModel がフィルタリング・グルーピング・削除を担当
enum SortOption: String, CaseIterable, Identifiable {
    case categoryAndDate = "カテゴリ別"
    case nextPaymentAscending = "請求日が近い順"
    case amountDescending = "金額が高い順"
    case satisfactionDescending = "満足度順"
    var id: String { rawValue }
}

@Observable
final class SubscriptionListViewModel {

    /// 検索バーのテキスト
    var searchText: String = ""

    /// カテゴリフィルタ（nilなら全カテゴリ表示）
    var selectedCategory: Category?
    
    /// 現在アクティブな（isActive == true）サブスクリプションの総数を取得する。
    func activeSubscriptionCount(_ subscriptions: [Subscription]) -> Int {
        subscriptions.filter { $0.isActive }.count
    }
    
    /// 無料枠の上限（10件）に達しているかどうか（10件以上かつProプラン未開放）。
    func isFreeLimitReached(_ subscriptions: [Subscription]) -> Bool {
        guard !ProManager.shared.isProUnlocked else { return false }
        return activeSubscriptionCount(subscriptions) >= 10
    }

    /// 用途フィルタ
    var expenseFilter: ExpenseFilter = .all

    /// 並び替えオプション
    var sortOption: SortOption = .categoryAndDate

    /// サブスクリプションをフィルタリングおよびソートする。
    func filteredSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        var result = subscriptions

        if !searchText.isEmpty {
            result = result.filter { subscription in
                subscription.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        switch expenseFilter {
        case .all: break
        case .privateOnly: result = result.filter { !$0.isExpense }
        case .expenseOnly: result = result.filter { $0.isExpense }
        }

        return result
    }

    /// 指定されたオプションでソートする
    func sortedSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        switch sortOption {
        case .categoryAndDate:
            // カテゴリ別表示の場合はView側で groupedByCategory を使うため、ここでは何もしない
            return subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
        case .nextPaymentAscending:
            return subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
        case .amountDescending:
            return subscriptions.sorted { $0.monthlyAmount > $1.monthlyAmount }
        case .satisfactionDescending:
            return subscriptions.sorted { $0.satisfaction > $1.satisfaction }
        }
    }

    /// サブスクリプションをカテゴリ別にグループ化する。
    /// Category.allCases の定義順でソートされるため、表示順が常に安定する。
    func groupedByCategory(
        _ subscriptions: [Subscription]
    ) -> [(category: Category, subscriptions: [Subscription])] {
        let grouped = Dictionary(grouping: subscriptions) { $0.category }
        return Category.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category: category, subscriptions: items)
        }
    }

    /// スワイプ削除の処理（複数またはインデックス指定での一括用）。
    /// ModelContext はView側の @Environment から受け取る設計。
    /// 削除時に対応するリマインド通知もキャンセルする。
    func deleteSubscriptions(
        from subscriptions: [Subscription],
        at offsets: IndexSet,
        using modelContext: ModelContext
    ) {
        for index in offsets {
            let subscription = subscriptions[index]
            deleteSubscription(subscription, using: modelContext)
        }
    }

    /// サブスクリプションを完全に削除する。
    func deleteSubscription(_ subscription: Subscription, using modelContext: ModelContext) {
        let notificationID = NotificationService.makeIdentifier(
            name: subscription.name, startDate: subscription.startDate
        )
        NotificationService.cancelReminder(identifier: notificationID)
        NotificationService.cancelReminder(identifier: notificationID + "_trial")
        NotificationService.cancelReminder(identifier: notificationID + "_end")

        // 必要な情報を退避
        let name = subscription.name
        let eventID = subscription.calendarEventIdentifier
        let trialEventID = subscription.trialCalendarEventIdentifier

        // カレンダーイベントの削除
        Task {
            await CalendarService.removeEvents(
                name: name,
                eventIdentifier: eventID,
                trialEventIdentifier: trialEventID
            )
        }

        modelContext.delete(subscription)
    }

    /// サブスクリプションを解約し、削減履歴に移行して元のデータを削除する。
    func reduceSubscription(_ subscription: Subscription, using modelContext: ModelContext) -> ReductionHistory {
        let history = ReductionHistory(
            name: subscription.name,
            amount: subscription.amount,
            billingCycle: subscription.billingCycle,
            category: subscription.category,
            cancelledDate: Date(),
            iconName: subscription.iconName,
            originalMemo: subscription.notes.isEmpty ? nil : subscription.notes
        )
        
        modelContext.insert(history)

        let notificationID = NotificationService.makeIdentifier(
            name: subscription.name, startDate: subscription.startDate
        )
        NotificationService.cancelReminder(identifier: notificationID)
        NotificationService.cancelReminder(identifier: notificationID + "_trial")
        NotificationService.cancelReminder(identifier: notificationID + "_end")

        // 必要な情報を退避
        let name = subscription.name
        let eventID = subscription.calendarEventIdentifier
        let trialEventID = subscription.trialCalendarEventIdentifier

        // カレンダーイベントの削除
        Task {
            await CalendarService.removeEvents(
                name: name,
                eventIdentifier: eventID,
                trialEventIdentifier: trialEventID
            )
        }

        modelContext.delete(subscription)
        
        return history
    }
}
