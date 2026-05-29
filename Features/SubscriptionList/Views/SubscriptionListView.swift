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
    
    /// Proアップグレード画面の表示制御フラグ
    @State private var showingProUpgradeSheet = false
    
    /// ProManagerの監視用（リアクティブな状態購読用）
    private var proManager = ProManager.shared

    // 月1見直しリマインダー連携用
    @AppStorage("monthlyReviewNotificationEnabled") private var monthlyReviewNotificationEnabled = false
    @AppStorage("monthlyReviewDay") private var monthlyReviewDay = 25
    @AppStorage("monthlyReviewHour") private var monthlyReviewHour = 9
    @AppStorage("monthlyReviewMinute") private var monthlyReviewMinute = 0
    @AppStorage("monthlyReviewCalendarEnabled") private var monthlyReviewCalendarEnabled = false
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false

    // アプリテーマ取得用
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }

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
            VStack(spacing: 0) {
                // 用途フィルタ用セグメント
                Picker("用途", selection: $viewModel.expenseFilter) {
                    ForEach(ExpenseFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 月1コテサク見直しデーが未登録で、サブスクが1件以上ある場合のみ、美しきインラインバナーを表示
                if !monthlyReviewNotificationEnabled && !subscriptions.isEmpty {
                    monthlyReviewNudgeBanner
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Group {
                    if subscriptions.isEmpty {
                        emptyStateView
                    } else {
                        subscriptionList
                    }
                }
                
                limitStatusBar
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
                    HStack {
                        Menu {
                            Picker("並び替え", selection: $viewModel.sortOption) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Label("並び替え", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button {
                            showingAddView = true
                        } label: {
                            Label("追加", systemImage: "plus")
                        }
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
            .sheet(isPresented: $showingProUpgradeSheet) {
                ProUpgradeSheet()
            }
        }
    }

    // MARK: - インライン月1コテサク見直し登録バナー (未登録ユーザー向け)
    
    private var monthlyReviewNudgeBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // 美しい光彩を放つテーマカラーのアイコン
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: currentTheme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .shadow(color: currentTheme.color.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("月1回のコテサク見直しを始めませんか？")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Text("節約効果 💡")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LinearGradient(colors: currentTheme.gradientColors, startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                    
                    Text("給料日前後の「毎月25日」に見直し診断を行うだけで、年間平均3〜5万円の無駄な“払い損”を防止できます。忘れがちなサブスク管理を完全に自動化しましょう。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    // 1タップ登録処理 (Haptic Feedback)
                    #if os(iOS)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    #endif
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        monthlyReviewDay = 25
                        monthlyReviewNotificationEnabled = true
                        monthlyReviewCalendarEnabled = true
                    }
                    
                    Task {
                        let authorized = await NotificationService.requestAuthorization()
                        if authorized {
                            await NotificationService.scheduleMonthlyReviewReminder(day: 25, hour: 9, minute: 0)
                            
                            if calendarSyncEnabled {
                                let calAuthorized = await CalendarService.requestAuthorization()
                                if calAuthorized {
                                    await CalendarService.syncMonthlyReviewEvents(day: 25)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("給料日の25日にリマインドを設定 (1タップ)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 14)
                    .background(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    // 設定画面へ遷移する通知を投稿
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettingsTab"), object: nil)
                } label: {
                    Text("別の日を設定")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal)
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

    /// サブスクリプションのリスト
    private var subscriptionList: some View {
        let filtered = viewModel.filteredSubscriptions(subscriptions)
        
        return List {
            if viewModel.sortOption == .categoryAndDate {
                let grouped = viewModel.groupedByCategory(filtered)
                ForEach(grouped, id: \.category) { group in
                    Section {
                        ForEach(group.subscriptions) { subscription in
                            rowView(for: subscription)
                        }
                    } header: {
                        Label(group.category.displayName, systemImage: group.category.iconName)
                    }
                }
            } else {
                let sorted = viewModel.sortedSubscriptions(filtered)
                ForEach(sorted) { subscription in
                    rowView(for: subscription)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    private func rowView(for subscription: Subscription) -> some View {
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
                
                Button {
                    toggleNotification(for: subscription)
                } label: {
                    Label(subscription.isNotificationEnabled ? "消音" : "通知",
                          systemImage: subscription.isNotificationEnabled ? "bell.slash" : "bell")
                }
                .tint(.orange)
            }
    }
    
    private func toggleNotification(for subscription: Subscription) {
        // Haptic Feedback
        #if os(iOS)
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        #endif
        
        subscription.isNotificationEnabled.toggle()
        try? modelContext.save()
        
        Task {
            let notificationID = NotificationService.makeIdentifier(
                name: subscription.name, startDate: subscription.startDate
            )
            
            if subscription.isNotificationEnabled {
                // 通知をスケジュール
                let authorized = await NotificationService.requestAuthorization()
                if authorized {
                    let leadDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
                    let actualLeadDays = leadDays > 0 ? leadDays : 1
                    
                    await NotificationService.scheduleReminder(
                        subscriptionName: subscription.name,
                        nextPaymentDate: subscription.nextPaymentDate,
                        identifier: notificationID,
                        leadDays: actualLeadDays
                    )
                }
            } else {
                // 通知をキャンセル
                NotificationService.cancelReminder(identifier: notificationID)
            }
        }
    }
    
    /// 無料枠上限の表示およびProアップグレードへの誘導を司るステータスバー
    private var limitStatusBar: some View {
        let activeCount = viewModel.activeSubscriptionCount(subscriptions)
        let isPro = proManager.isProUnlocked
        
        return Group {
            if !isPro {
                Button {
                    showingProUpgradeSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                        
                        Text("登録状況: \(activeCount) / 10件（残り \(max(0, 10 - activeCount))枠）")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("不要なサブスクを削減すると枠が増えます 💡")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.accentColor)
                    
                    Text("コテサク Pro 有効（登録上限なし）")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
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
