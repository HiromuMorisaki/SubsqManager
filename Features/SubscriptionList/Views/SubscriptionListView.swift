//
//  SubscriptionListView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// サブスクリプション一覧画面。
/// カテゴリ別にグループ化されたリスト表示と、スワイプ削除機能を提供する。
struct SubscriptionListView: View {

    // MARK: - プロパティ

    /// @Query: SwiftDataの自動クエリプロパティラッパー。
    /// - ModelContainerに保存されたSubscriptionを自動取得し、変更を監視する
    /// - filter: isActive == true のサブスクのみ取得
    /// - sort: nextPaymentDate の昇順（次の請求日が近い順）
    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true },
        sort: \Subscription.nextPaymentDate
    ) private var subscriptions: [Subscription]

    /// SwiftDataの挿入・削除・更新操作に必要なコンテキスト。
    @Environment(\.modelContext) private var modelContext

    /// @State で @Observable な ViewModel を保持。
    /// プロパティ変更時に自動で再描画される。
    @State private var viewModel = SubscriptionListViewModel()

    /// サブスク追加シートの表示制御フラグ
    @State private var showingAddSheet = false

    /// 編集対象のサブスクリプション（nilなら編集シート非表示）
    @State private var editingSubscription: Subscription?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    emptyStateView
                } else {
                    subscriptionList
                }
            }
            .navigationTitle("サブスクリプション")
            .searchable(text: $viewModel.searchText, prompt: "サブスクを検索")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: PastSubscriptionsView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                #else
                ToolbarItem(placement: .navigation) {
                    NavigationLink(destination: PastSubscriptionsView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                #endif
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
            }
            .sheet(item: $editingSubscription) { subscription in
                EditSubscriptionView(subscription: subscription)
            }
        }
    }

    // MARK: - サブビュー

    /// サブスクが0件の場合に表示する空状態ビュー
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("サブスクがありません", systemImage: "creditcard")
        } description: {
            Text("右上の＋ボタンからサブスクを追加してください")
        }
    }

    /// カテゴリ別にグループ化されたサブスクリプションのリスト
    private var subscriptionList: some View {
        let filtered = viewModel.filteredSubscriptions(subscriptions)
        let grouped = viewModel.groupedByCategory(filtered)

        return List {
            ForEach(grouped, id: \.category) { group in
                Section {
                    ForEach(group.subscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingSubscription = subscription
                            }
                    }
                    .onDelete { offsets in
                        viewModel.deleteSubscriptions(
                            from: group.subscriptions,
                            at: offsets,
                            using: modelContext
                        )
                    }
                } header: {
                    Label(group.category.displayName, systemImage: group.category.iconName)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
}

// MARK: - 行ビュー

/// 一覧リストの各行を表示する子View。
/// サブスク名、金額、請求サイクル、次回請求日を1行で表示する。
struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: subscription.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)

                Text("次回: \(subscription.nextPaymentDate, format: .dateTime.month().day())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyHelper.formatted(amount: subscription.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(subscription.billingCycle.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SubscriptionListView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
