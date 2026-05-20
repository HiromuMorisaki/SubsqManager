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
@Observable
final class SubscriptionListViewModel {

    /// 検索バーのテキスト
    var searchText: String = ""

    /// カテゴリフィルタ（nilなら全カテゴリ表示）
    var selectedCategory: Category?

    /// サブスクリプションを検索テキストとカテゴリでフィルタリングする。
    /// - Parameter subscriptions: @Queryで取得された全アクティブサブスクリプション
    /// - Returns: フィルタ条件に一致するサブスクリプションの配列
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

        return result
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

    /// スワイプ削除の処理。
    /// ModelContext はView側の @Environment から受け取る設計。
    /// 削除時に対応するリマインド通知もキャンセルする。
    func deleteSubscriptions(
        from subscriptions: [Subscription],
        at offsets: IndexSet,
        using modelContext: ModelContext
    ) {
        for index in offsets {
            let subscription = subscriptions[index]

            // 対応する通知をキャンセル
            let notificationID = NotificationService.makeIdentifier(
                name: subscription.name, startDate: subscription.startDate
            )
            NotificationService.cancelReminder(identifier: notificationID)

            modelContext.delete(subscription)
        }
    }
}
