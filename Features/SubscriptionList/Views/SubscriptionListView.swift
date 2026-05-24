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

    /// サブスク追加画面の表示制御フラグ
    @State private var showingAddView = false

    /// 編集対象のサブスクリプション（nilなら編集シート非表示）
    @State private var editingSubscription: Subscription?

    /// 解約/削除アクション確認対象のサブスクリプション
    @State private var subscriptionToProcess: Subscription?
    @State private var showingActionSheet = false

    /// お祝い画面用のプレデータ構造体
    struct CelebrationData: Identifiable {
        let id = UUID()
        let name: String
        let amount: Decimal
        let billingCycle: BillingCycle
        let category: Category
        let iconName: String
    }
    @State private var celebrationData: CelebrationData?

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
                        showingAddView = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                NavigationStack {
                    AddSubscriptionView(isModal: true)
                }
            }
            .sheet(item: $editingSubscription) { subscription in
                EditSubscriptionView(subscription: subscription)
            }
            .confirmationDialog(
                "サブスクリプションの処理",
                isPresented: $showingActionSheet,
                titleVisibility: .visible,
                presenting: subscriptionToProcess
            ) { sub in
                Button("解約（固定費削減）として記録 🌟") {
                    let history = viewModel.reduceSubscription(sub, using: modelContext)
                    celebrationData = CelebrationData(
                        name: history.name,
                        amount: history.amount,
                        billingCycle: history.billingCycle,
                        category: history.category,
                        iconName: history.iconName
                    )
                }
                
                Button("完全に削除", role: .destructive) {
                    viewModel.deleteSubscription(sub, using: modelContext)
                }
                
                Button("キャンセル", role: .cancel) {
                    subscriptionToProcess = nil
                }
            } message: { sub in
                Text("「\(sub.name)」を解約しましたか？\n解約済みの場合は「削減として記録」することで、浮いた固定費の積み上げ実績に反映されます。")
            }
            .sheet(item: $celebrationData) { data in
                ReductionCelebrationView(
                    serviceName: data.name,
                    amount: data.amount,
                    billingCycle: data.billingCycle,
                    category: data.category,
                    iconName: data.iconName
                )
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    subscriptionToProcess = subscription
                                    showingActionSheet = true
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
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

                HStack(spacing: 6) {
                    Text("次回: \(subscription.nextPaymentDate, format: .dateTime.month().day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if subscription.paymentMethod != .notSet {
                        HStack(spacing: 2) {
                            Image(systemName: subscription.paymentMethod.iconName)
                            Text(subscription.paymentMethod.rawValue)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                        .foregroundStyle(.secondary)
                    }
                    
                    if !subscription.isNotificationEnabled {
                        Image(systemName: "bell.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.red.opacity(0.7))
                    }
                }
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
