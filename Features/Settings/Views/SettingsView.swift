//
//  SettingsView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData
import EventKit

/// 設定画面。通知ON/OFF、通貨選択、アプリ情報を表示する。
///
/// ### @AppStorage について
/// UserDefaultsの値をSwiftUIのプロパティとしてバインドする仕組み。
/// 値を変更すると自動的にUserDefaultsに保存され、アプリ再起動後も保持される。
/// @State と同様にViewの再描画もトリガーする。
struct SettingsView: View {
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showingOnboarding = false

    /// 通知のON/OFFフラグ（UserDefaultsに永続化）
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    /// 通知を送る何日前か（UserDefaultsに永続化、デフォルトは1日前）
    @AppStorage("notificationLeadDays") private var notificationLeadDays = 1

    /// 選択中の通貨コード（UserDefaultsに永続化）
    @AppStorage("currencyCode") private var currencyCode = "JPY"

    /// カレンダー自動連携のON/OFFフラグ（UserDefaultsに永続化）
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false

    /// 選択中の連携先カレンダーのID（UserDefaultsに永続化）
    @AppStorage("selectedCalendarIdentifier") private var selectedCalendarIdentifier = ""

    /// 書き込み可能なカレンダー一覧
    @State private var availableCalendars: [EKCalendar] = []

    /// Apple IDインポートアシスタント表示フラグ
    @State private var showingAppleImporter = false

    /// TimeTree 連携ガイド表示フラグ
    @State private var showingTimeTreeGuide = false

    /// 現在のアプリテーマ
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    
    /// 現在のアプリアイコン
    @State private var currentAppIcon = AppIcon.current

    @State private var isSyncing = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncSuccessAlert = false
    @State private var showingSyncErrorAlert = false
    @State private var alertMessage = ""

    // MARK: - Body

    var body: some View {
        let themeColor = AppTheme(rawValue: appThemeRawValue)?.color ?? .green
        
        NavigationStack {
            Form {
                appearanceSection
                notificationSection
                calendarSection
                externalIntegrationSection
                currencySection
                dataSection
                helpSection
                appInfoSection
            }
            .tint(themeColor)
            .accentColor(themeColor)
            .id(appThemeRawValue) // iOS of Formにおける再レンダリングバグを解決するためにID変更
            .navigationTitle("設定")
            .alert("完了", isPresented: $showingSyncSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("アクセス権限エラー", isPresented: $showingSyncErrorAlert) {
                Button("キャンセル", role: .cancel) {}
                #if os(iOS)
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                #endif
            } message: {
                Text(alertMessage)
            }
            .alert("カレンダー同期の確認", isPresented: $showingSyncConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("同期する") {
                    syncAllToCalendar()
                }
            } message: {
                Text("重複登録を防ぐため、すでにカレンダーに登録されているコテサクの請求予定を自動でクリーンアップ（削除）した上で再同期を行います。\n\nよろしいですか？")
            }
            .sheet(isPresented: $showingAppleImporter) {
                NavigationStack {
                    AppleSubscriptionImporterView()
                }
            }
            .sheet(isPresented: $showingTimeTreeGuide) {
                TimeTreeGuideView()
            }
            .task {
                fetchCalendars()
            }
        }
    }

    // MARK: - セクション

    /// 外観設定セクション
    private var appearanceSection: some View {
        Section {
            // テーマカラー選択
            VStack(alignment: .leading, spacing: 12) {
                Text("テーマカラー")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AppTheme.allCases) { theme in
                            VStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: appThemeRawValue == theme.rawValue ? 3 : 0)
                                            .padding(-4)
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            appThemeRawValue = theme.rawValue
                                        }
                                    }
                                
                                Text(theme.displayName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(appThemeRawValue == theme.rawValue ? .primary : .secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 4)
            
            // アプリアイコン選択
            Picker("アプリアイコン", selection: $currentAppIcon) {
                ForEach(AppIcon.allCases) { icon in
                    Text(icon.displayName).tag(icon)
                }
            }
            .onChange(of: currentAppIcon) { _, newValue in
                newValue.apply()
            }
        } header: {
            Label("外観", systemImage: "paintbrush")
        }
    }

    /// 通知設定セクション
    private var notificationSection: some View {
        Section {
            Toggle("請求日リマインド", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    rescheduleAllNotifications(enabled: newValue, leadDays: notificationLeadDays)
                }

            if notificationsEnabled {
                Picker("通知のタイミング", selection: $notificationLeadDays) {
                    Text("1日前").tag(1)
                    Text("2日前").tag(2)
                    Text("3日前").tag(3)
                    Text("7日前").tag(7)
                }
                .onChange(of: notificationLeadDays) { _, newValue in
                    rescheduleAllNotifications(enabled: notificationsEnabled, leadDays: newValue)
                }
            }
        } header: {
            Label("通知", systemImage: "bell")
        } footer: {
            Text(notificationsEnabled
                 ? "請求日の\(notificationLeadDays == 1 ? "前日" : "\(notificationLeadDays)日前")の午前9時に通知でお知らせします"
                 : "ONにすると、請求日の指定日前に通知でお知らせします")
        }
    }

    /// カレンダー連携設定セクション
    private var calendarSection: some View {
        Section {
            Toggle("カレンダー自動連携", isOn: $calendarSyncEnabled)
                .onChange(of: calendarSyncEnabled) { _, newValue in
                    handleCalendarSyncToggled(enabled: newValue)
                }

            if calendarSyncEnabled {
                if !availableCalendars.isEmpty {
                    Picker("同期先カレンダー", selection: $selectedCalendarIdentifier) {
                        Text("デフォルト").tag("")
                        ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor))
                                    .frame(width: 8, height: 8)
                                Text(calendar.title)
                            }
                            .tag(calendar.calendarIdentifier)
                        }
                    }
                    .onChange(of: selectedCalendarIdentifier) { _, _ in
                        Task { @MainActor in
                            isSyncing = true
                            await CalendarService.removeAllEvents(for: subscriptions)
                            await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
                            isSyncing = false
                        }
                    }
                }

                Button {
                    showingSyncConfirmation = true
                } label: {
                    HStack {
                        Label("既存データをカレンダーに同期", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)
            }
        } header: {
            Label("カレンダー連携", systemImage: "calendar")
        } footer: {
            Text("有効にすると、サブスクの次回請求日や無料トライアル終了日が自動的にカレンダーに登録されます。GoogleカレンダーやTimeTreeなどの同期カレンダーを登録すれば、それらのアプリにも反映されます。")
        }
    }

    /// 通貨選択セクション
    private var currencySection: some View {
        Section {
            Picker("通貨", selection: $currencyCode) {
                ForEach(Self.availableCurrencies, id: \.code) { currency in
                    Text("\(currency.symbol) \(currency.name)")
                        .tag(currency.code)
                }
            }
        } header: {
            Label("表示設定", systemImage: "yensign.circle")
        }
    }

    /// データ管理セクション
    private var dataSection: some View {
        Section {
            let csvDocument = CSVExportDocument(csvString: viewModel.generateCSV(from: subscriptions))
            ShareLink(
                item: csvDocument,
                preview: SharePreview("サブスクリプション一覧.csv", image: Image(systemName: "tablecells"))
            ) {
                HStack {
                    Label("CSVデータを書き出す", systemImage: "square.and.arrow.up")
                    Spacer()
                }
            }
        } header: {
            Label("データ管理", systemImage: "externaldrive")
        } footer: {
            Text("登録されているすべてのデータをCSV形式でエクスポートします")
        }
    }

    /// ヘルプセクション
    private var helpSection: some View {
        Section {
            SettingsRow(
                iconName: "questionmark.circle",
                iconColor: .blue,
                title: "アプリの使い方を見る",
                subtitle: nil
            ) {
                showingOnboarding = true
            }

            SettingsRow(
                iconName: "envelope",
                iconColor: .orange,
                title: "ご意見・お問い合わせ",
                subtitle: nil,
                isExternal: true
            ) {
                openMailApp()
            }

            if let url = URL(string: "https://kotesaku.notion.site/e2df7871a2394136ad71216a272eb0bb") {
                SettingsRow(
                    iconName: "hand.raised",
                    iconColor: .purple,
                    title: "プライバシーポリシー",
                    subtitle: nil,
                    isExternal: true
                ) {
                    UIApplication.shared.open(url)
                }
            }
        } header: {
            Label("ヘルプ", systemImage: "info.circle")
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView {
                showingOnboarding = false
            }
        }
    }

    /// アプリ情報セクション
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text(Self.appVersion)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("ビルド")
                Spacer()
                Text(Self.buildNumber)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("アプリ情報", systemImage: "info.circle")
        }
    }

    // MARK: - 定数

    /// 選択可能な通貨リスト
    private static let availableCurrencies: [(code: String, symbol: String, name: String)] = [
        ("JPY", "¥", "日本円"),
        ("USD", "$", "米ドル"),
        ("EUR", "€", "ユーロ"),
        ("GBP", "£", "英ポンド"),
        ("KRW", "₩", "韓国ウォン"),
        ("CNY", "¥", "中国元"),
    ]

    /// アプリバージョン（Info.plistから取得）
    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// ビルド番号（Info.plistから取得）
    private static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 全てのリマインド通知を再スケジュールする
    private func rescheduleAllNotifications(enabled: Bool, leadDays: Int) {
        Task {
            if enabled {
                // 重複を防ぐため、一度すべての通知をキャンセルしてから再スケジュール
                NotificationService.cancelAllReminders()
                
                for subscription in subscriptions where subscription.isActive {
                    let id = NotificationService.makeIdentifier(
                        name: subscription.name, startDate: subscription.startDate
                    )
                    await NotificationService.scheduleReminder(
                        subscriptionName: subscription.name,
                        nextPaymentDate: subscription.nextPaymentDate,
                        identifier: id,
                        leadDays: leadDays
                    )
                    if let trialEnd = subscription.trialEndDate {
                        await NotificationService.scheduleTrialReminder(
                            subscriptionName: subscription.name,
                            trialEndDate: trialEnd,
                            identifier: id + "_trial"
                        )
                    }
                    if let endDate = subscription.endDate {
                        await NotificationService.scheduleEndDateReminder(
                            subscriptionName: subscription.name,
                            endDate: endDate,
                            identifier: id + "_end"
                        )
                    }
                }
            } else {
                NotificationService.cancelAllReminders()
            }
        }
    }

    /// カレンダー連携のトグル切り替え時の処理
    private func handleCalendarSyncToggled(enabled: Bool) {
        Task { @MainActor in
            if enabled {
                let authorized = await CalendarService.requestAuthorization()
                if authorized {
                    fetchCalendars()
                    await SubscriptionDeduplicator.deduplicateActiveSubscriptions(using: modelContext)
                    await syncAllToCalendarSilently()
                } else {
                    calendarSyncEnabled = false
                    alertMessage = "カレンダーへのアクセス権限がありません。設定アプリからコテサクのカレンダー書き込み権限を許可してください。"
                    showingSyncErrorAlert = true
                }
            } else {
                isSyncing = true
                await CalendarService.removeAllEvents(for: subscriptions)
                isSyncing = false
                availableCalendars = []
                alertMessage = "カレンダーの同期設定をオフにし、登録されたすべてのイベントを削除しました。"
                showingSyncSuccessAlert = true
            }
        }
    }

    /// カレンダー一覧を取得する
    private func fetchCalendars() {
        if calendarSyncEnabled && CalendarService.isAuthorized {
            availableCalendars = CalendarService.getWritableCalendars()
        } else {
            availableCalendars = []
        }
    }

    /// カレンダーへの一括サイレント同期
    private func syncAllToCalendarSilently() async {
        guard CalendarService.isAuthorized else { return }
        await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
    }

    /// 既存データをカレンダーに一括同期する（インジケータ表示付き）
    private func syncAllToCalendar() {
        Task { @MainActor in
            isSyncing = true
            let authorized = await CalendarService.requestAuthorization()
            if authorized {
                fetchCalendars()
                await SubscriptionDeduplicator.deduplicateActiveSubscriptions(using: modelContext)
                await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
                alertMessage = "既存のサブスクリプション（\(subscriptions.count)件）をカレンダーに同期しました。"
                showingSyncSuccessAlert = true
            } else {
                alertMessage = "カレンダーへのアクセス権限がありません。設定アプリからコテサクのカレンダー書き込み権限を許可してください。"
                showingSyncErrorAlert = true
            }
            isSyncing = false
        }
    }

    /// 外部サービス連携セクション（Apple ID、TimeTree）
    private var externalIntegrationSection: some View {
        Section {
            SettingsRow(
                iconName: "applelogo",
                iconColor: .primary,
                title: "Apple ID サブスク連携",
                subtitle: "Apple Store決済サービスを高速一括インポート"
            ) {
                showingAppleImporter = true
            }
            
            SettingsRow(
                iconName: "arrow.triangle.2.circlepath",
                iconColor: .green,
                title: "TimeTree 連携ガイド",
                subtitle: "iOSカレンダーを介したTimeTreeへの自動同期設定手順"
            ) {
                showingTimeTreeGuide = true
            }
        } header: {
            Label("外部サービス高度連携", systemImage: "link.badge.plus")
        } footer: {
            Text("Apple IDサブスク連携では、Apple Store決済中のサービスを一挙にインポートできます。\nTimeTree連携では、iOS標準カレンダーを介してTimeTreeへ次回請求予定を全自動で同期させる手順を解説します。")
        }
    }

    /// お問い合わせ用メールアプリ起動
    private func openMailApp() {
        let email = "support@kotesaku.app"
        let subject = "【コテサク】お問い合わせ・ご要望"
        let body = "\n\nアプリへのご意見や不具合報告をご記入ください。"
        
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - カスタム設定行コンポーネント (再利用可能)

struct SettingsRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var isExternal: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
