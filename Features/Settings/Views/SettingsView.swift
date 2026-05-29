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
    
    /// Proアップグレードシート表示フラグ
    @State private var showingProUpgrade = false

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

    /// 月1見直しリマインド通知のON/OFFフラグ（UserDefaultsに永続化）
    @AppStorage("monthlyReviewNotificationEnabled") private var monthlyReviewNotificationEnabled = false

    /// 月1見直しリマインドを送る日にち（1〜31）（UserDefaultsに永続化、デフォルトは25日）
    @AppStorage("monthlyReviewDay") private var monthlyReviewDay = 25

    /// 月1見直しリマインドを送る時間（時）（UserDefaultsに永続化、デフォルトは9時）
    @AppStorage("monthlyReviewHour") private var monthlyReviewHour = 9

    /// 月1見直しリマインドを送る時間（分）（UserDefaultsに永続化、デフォルトは0分）
    @AppStorage("monthlyReviewMinute") private var monthlyReviewMinute = 0

    /// 月1見直し予定のカレンダー追加ON/OFFフラグ（UserDefaultsに永続化）
    @AppStorage("monthlyReviewCalendarEnabled") private var monthlyReviewCalendarEnabled = false

    /// DatePicker選択用の一時変数
    @State private var selectedReviewTime = Date()

    /// 書き込み可能なカレンダー一覧
    @State private var availableCalendars: [EKCalendar] = []

    /// Apple IDインポートアシスタント表示フラグ
    @State private var showingAppleImporter = false

    /// 現在のアプリテーマ
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    
    /// 現在のアプリアイコン
    @State private var currentAppIcon = AppIcon.current

    /// 現在のテーマカラー (helper views からも参照可能に)
    private var themeColor: Color {
        AppTheme(rawValue: appThemeRawValue)?.color ?? .green
    }

    /// 現在のテーマのグラデーションカラー
    private var themeGradientColors: [Color] {
        AppTheme(rawValue: appThemeRawValue)?.gradientColors ?? [.green, .teal]
    }

    @State private var isSyncing = false
    @State private var showingSyncConfirmation = false
    @State private var showingSyncSuccessAlert = false
    @State private var showingSyncErrorAlert = false
    @State private var alertMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                proSection
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
            .sheet(isPresented: $showingProUpgrade) {
                ProUpgradeSheet()
            }
            .task {
                fetchCalendars()
                initializeReviewTime()
            }
            .onChange(of: selectedReviewTime) { _, newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                monthlyReviewHour = components.hour ?? 9
                monthlyReviewMinute = components.minute ?? 0
                updateMonthlyReviewNotification()
            }
        }
    }
    
    /// Proプランのセクション
    private var proSection: some View {
        let isPro = ProManager.shared.isProUnlocked
        let themeColor = AppTheme(rawValue: appThemeRawValue)?.color ?? .green
        
        return Section {
            Button {
                showingProUpgrade = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [themeColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isPro ? "コテサク Pro 有効化済み" : "コテサク Pro にアップグレード")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(isPro ? "すべての制限が解除され、全機能が有効です 👑" : "登録上限の解放、OCR無制限、複数通知などをアンロック")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        } header: {
            Label("アカウント & メンバーシップ", systemImage: "person.crop.circle.badge.checkmark")
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

            // 月1コテサク見直しDAY設定 (テーマカラー連動 ＆ 美しいグラデーションと動的発光でプレミアム感を最大化)
            HStack(spacing: 12) {
                ZStack {
                    if monthlyReviewNotificationEnabled {
                        Circle()
                            .fill(LinearGradient(
                                colors: themeGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                            .shadow(color: themeColor.opacity(0.35), radius: 5, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 36, height: 36)
                    }
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(monthlyReviewNotificationEnabled ? .white : Color.secondary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("月1コテサク見直しDAY")
                            .font(.system(size: 14, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85) // 幅が狭い画面でも改行させず綺麗に収める
                            .layoutPriority(1) // 2行回り込み（改行）を防止
                        
                        Text("節約 🚀")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Group {
                                    if monthlyReviewNotificationEnabled {
                                        LinearGradient(
                                            colors: themeGradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                    
                    Text("無駄な固定費を削減して家計を最適化する日")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                
                Spacer()
                
                Toggle("", isOn: $monthlyReviewNotificationEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: themeColor)) // テーマカラーのインジケーター
            }
            .padding(.vertical, 4)
            .listRowBackground(
                Group {
                    if monthlyReviewNotificationEnabled {
                        // プレミアムな発光効果：テーマカラーに合わせた極薄のグラデーション背景
                        LinearGradient(
                            colors: [themeColor.opacity(0.08), themeColor.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.secondarySystemGroupedBackground)
                    }
                }
            )
            .onChange(of: monthlyReviewNotificationEnabled) { _, newValue in
                if newValue {
                    Task {
                        let authorized = await NotificationService.requestAuthorization()
                        if !authorized {
                            monthlyReviewNotificationEnabled = false
                            alertMessage = "通知権限がありません。設定アプリから通知を許可してください。"
                            showingSyncErrorAlert = true
                        } else {
                            updateMonthlyReviewNotification()
                        }
                    }
                } else {
                    updateMonthlyReviewNotification()
                }
            }

            if monthlyReviewNotificationEnabled {
                Picker("リマインド日", selection: $monthlyReviewDay) {
                    ForEach(1...31, id: \.self) { day in
                        if day == 31 {
                            Text("毎月 31 日 (または月末)").tag(day)
                        } else {
                            Text("毎月 \(day) 日").tag(day)
                        }
                    }
                }
                .onChange(of: monthlyReviewDay) { _, _ in
                    updateMonthlyReviewNotification()
                    if calendarSyncEnabled && monthlyReviewCalendarEnabled {
                        updateMonthlyReviewCalendar()
                    }
                }

                DatePicker("通知時間", selection: $selectedReviewTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Label("通知", systemImage: "bell")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if notificationsEnabled {
                    Text("請求日の\(notificationLeadDays == 1 ? "前日" : "\(notificationLeadDays)日前")の午前9時に通知でお知らせします")
                }
                if monthlyReviewNotificationEnabled {
                    let timeFormatted = selectedReviewTime.formatted(date: .omitted, time: .shortened)
                    let dayString = monthlyReviewDay == 31 ? "31 日 (または月末)" : "\(monthlyReviewDay) 日"
                    Text("毎月 \(dayString) の \(timeFormatted) にサブスク見直しを促す通知でお知らせします")
                        .foregroundColor(themeColor)
                        .fontWeight(.semibold)
                }
                if !notificationsEnabled && !monthlyReviewNotificationEnabled {
                    Text("ONにすると、請求日や定期的な見直し日に通知でお知らせします")
                }
            }
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
                            // iOS 14+ のネイティブメニュー平坦化バグを防ぐため、HStack を廃止し単一テキストで表現
                            Text("\(calendar.title) (\(friendlySourceName(for: calendar)))")
                                .tag(calendar.calendarIdentifier)
                        }
                    }
                    .onChange(of: selectedCalendarIdentifier) { _, _ in
                        Task { @MainActor in
                            isSyncing = true
                            await CalendarService.removeAllEvents(for: subscriptions)
                            await CalendarService.removeMonthlyReviewEvents()
                            await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
                            if monthlyReviewCalendarEnabled {
                                await CalendarService.syncMonthlyReviewEvents(day: monthlyReviewDay)
                            }
                            isSyncing = false
                        }
                    }
                }

                Toggle("月1コテサクリマインドを追加", isOn: $monthlyReviewCalendarEnabled)
                    .onChange(of: monthlyReviewCalendarEnabled) { _, newValue in
                        updateMonthlyReviewCalendar()
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
                    SubscriptionDeduplicator.deduplicateActiveSubscriptions(using: modelContext)
                    await syncAllToCalendarSilently()
                } else {
                    calendarSyncEnabled = false
                    alertMessage = "カレンダーへのアクセス権限がありません。設定アプリからコテサクのカレンダー書き込み権限を許可してください。"
                    showingSyncErrorAlert = true
                }
            } else {
                isSyncing = true
                await CalendarService.removeAllEvents(for: subscriptions)
                await CalendarService.removeMonthlyReviewEvents()
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
            let writable = CalendarService.getWritableCalendars()
            // 「iPhone標準カレンダー」および「Googleカレンダー」の2つに厳密に絞り込み
            availableCalendars = writable.filter { calendar in
                let sourceName = friendlySourceName(for: calendar)
                return sourceName == "iPhone標準カレンダー" || sourceName == "Googleカレンダー"
            }
        } else {
            availableCalendars = []
        }
    }

    /// カレンダーへの一括サイレント同期
    private func syncAllToCalendarSilently() async {
        guard CalendarService.isAuthorized else { return }
        await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
        if monthlyReviewCalendarEnabled {
            await CalendarService.syncMonthlyReviewEvents(day: monthlyReviewDay)
        }
    }

    /// 既存データをカレンダーに一括同期する（インジケータ表示付き）
    private func syncAllToCalendar() {
        Task { @MainActor in
            isSyncing = true
            let authorized = await CalendarService.requestAuthorization()
            if authorized {
                fetchCalendars()
                SubscriptionDeduplicator.deduplicateActiveSubscriptions(using: modelContext)
                await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
                if monthlyReviewCalendarEnabled {
                    await CalendarService.syncMonthlyReviewEvents(day: monthlyReviewDay)
                }
                alertMessage = "既存のサブスクリプション（\(subscriptions.count)件）および見直し予定をカレンダーに同期しました。"
                showingSyncSuccessAlert = true
            } else {
                alertMessage = "カレンダーへのアクセス権限がありません。設定アプリからコテサクのカレンダー書き込み権限を許可してください。"
                showingSyncErrorAlert = true
            }
            isSyncing = false
        }
    }

    /// 外部サービス連携セクション（Apple ID）
    private var externalIntegrationSection: some View {
        Section {
            SettingsRow(
                iconName: "applelogo",
                iconColor: .primary,
                title: "Apple ID サブスク連携",
                subtitle: "Apple Store決済中のサービスをスクショから一括インポート"
            ) {
                showingAppleImporter = true
            }
        } header: {
            Label("外部サービスを確認・画像から登録", systemImage: "link")
        } footer: {
            Text("Apple IDサブスク連携では、App Storeアプリの「サブスクリプション」画面のスクリーンショットから、コテサクへデータを自動解析して高速一括インポートできます。")
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

    /// カレンダーのソース（アカウント）を分かりやすい日本語名に変換します
    private func friendlySourceName(for calendar: EKCalendar) -> String {
        let sourceTitle = calendar.source.title.lowercased()
        if sourceTitle.contains("icloud") {
            return "iPhone標準カレンダー"
        } else if sourceTitle.contains("google") || sourceTitle.contains("gmail") {
            return "Googleカレンダー"
        } else if calendar.source.sourceType == .local {
            return "iPhoneローカル"
        } else {
            return calendar.source.title
        }
    }

    /// 月1見直し通知時間の一時状態を初期化します
    private func initializeReviewTime() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = monthlyReviewHour
        components.minute = monthlyReviewMinute
        if let date = Calendar.current.date(from: components) {
            selectedReviewTime = date
        }
    }

    /// 月1見直し通知スケジュールを更新します
    private func updateMonthlyReviewNotification() {
        Task {
            if monthlyReviewNotificationEnabled {
                await NotificationService.scheduleMonthlyReviewReminder(
                    day: monthlyReviewDay,
                    hour: monthlyReviewHour,
                    minute: monthlyReviewMinute
                )
            } else {
                NotificationService.cancelMonthlyReviewReminder()
            }
        }
    }

    /// 月1見直しカレンダーイベントを更新します
    private func updateMonthlyReviewCalendar() {
        Task { @MainActor in
            if calendarSyncEnabled && monthlyReviewCalendarEnabled {
                let authorized = await CalendarService.requestAuthorization()
                if authorized {
                    await CalendarService.syncMonthlyReviewEvents(day: monthlyReviewDay)
                }
            } else {
                await CalendarService.removeMonthlyReviewEvents()
            }
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

// MARK: - ProUpgradeSheet

/// Proプランのアップグレード画面（ハーフシート）。
/// コテサクProで開放されるプレミアム価値を美しく訴求し、購入および復元アクションを提供する。
struct ProUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // ProManagerのObservable状態を購読
    @State private var proManager = ProManager.shared
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - ヘッダー（プレミアム感のあるネオン調）
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme(rawValue: appThemeRawValue)?.color ?? .green, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: (AppTheme(rawValue: appThemeRawValue)?.color ?? .green).opacity(0.5), radius: 15)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)
                    
                    Text("コテサク Pro")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.black)
                    
                    Text("無駄なサブスクを見直して、スマートに削減")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - プレミアム機能一覧
                VStack(spacing: 16) {
                    featureRow(
                        icon: "infinity",
                        color: .blue,
                        title: "登録枠を無制限に解放",
                        description: "10件の無料制限を完全撤廃。何個でも登録・管理可能。"
                    )
                    
                    featureRow(
                        icon: "camera.viewfinder",
                        color: .green,
                        title: "スクショ自動解析 (OCR) 無制限",
                        description: "領収書や明細スクショの自動読み込みを何回でも快適に。"
                    )
                    
                    featureRow(
                        icon: "bell.badge.fill",
                        color: .orange,
                        title: "複数リマインド通知",
                        description: "「3日前」「前日」「当日」など、複数回通知で解約漏れゼロへ。"
                    )
                    
                    featureRow(
                        icon: "doc.arrow.up.fill",
                        color: .purple,
                        title: "確定申告CSV/Excel書き出し",
                        description: "経費指定のサブスクデータを一括出力。freeeや弥生等に即インポート。"
                    )
                    
                    featureRow(
                        icon: "paintpalette.fill",
                        color: .pink,
                        title: "限定プレミアムテーマ＆アイコン",
                        description: "グラスモーフィズムを極限まで活かした限定カラーやアイコン群。"
                    )
                }
                .padding(.horizontal)
                
                // MARK: - 料金プランカード（戦略的価格 ＆ 最上位リオーダー）
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // 月額プラン
                        planCard(
                            title: "月額プラン",
                            price: "¥150/月",
                            subtitle: "いつでも解約可能",
                            isRecommended: false
                        ) {
                            proManager.unlockProManually()
                            dismiss()
                        }
                        
                        // 年額プラン (最推奨・1週間お試し)
                        planCard(
                            title: "年額プラン",
                            price: "¥980/年",
                            subtitle: "1週間無料体験付き",
                            isRecommended: true
                        ) {
                            proManager.unlockProManually()
                            dismiss()
                        }
                    }
                    
                    // 買い切りプラン（ライフタイム）- 下部に配置して圧迫感を軽減
                    planCard(
                        title: "一生使い放題 (買い切りライフタイム)",
                        price: "¥2,400",
                        subtitle: "追加課金なし・永久サポート ♾",
                        isRecommended: false
                    ) {
                        proManager.unlockProManually()
                        dismiss()
                    }
                }
                .padding(.horizontal)
                
                // MARK: - 美しき機能比較マトリクス
                comparisonMatrix
                
                
                // MARK: - フッター案内
                VStack(spacing: 8) {
                    Button {
                        // 復元処理（StoreKitのモック）
                        Task {
                            await proManager.updatePurchasedProducts()
                            if proManager.isProUnlocked {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("購入を復元 (Restore Purchases)")
                            .font(.footnote)
                            .foregroundColor(AppTheme(rawValue: appThemeRawValue)?.color ?? .green)
                    }
                    
                    Text("無料枠の範囲（最大10件）で使いたい場合は、不要なサブスクを1件「削減（非アクティブ化）」すれば、新しいサブスクを追加できます。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                
                // MARK: - 開発用デバッグエリア
                #if DEBUG
                VStack(spacing: 8) {
                    Divider()
                        .padding(.top)
                    
                    Text("🛠 開発用テスト機能")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Pro状態をトグル (現在: \(proManager.isProUnlocked ? "Pro" : "Free"))") {
                            proManager.debugToggleProStatus()
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                .padding(.bottom, 24)
                #endif
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 補助ビューコンポーネント
    
    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func planCard(title: String, price: String, subtitle: String, isRecommended: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme(rawValue: appThemeRawValue)?.color ?? .green)
                        .cornerRadius(10)
                        .padding(.top, -14)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text(price)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isRecommended ? (AppTheme(rawValue: appThemeRawValue)?.color ?? .green) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.top, isRecommended ? 12 : 0)
    }

    private var comparisonMatrix: some View {
        VStack(spacing: 12) {
            Text("無料プラン と Proプラン の比較")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, 16)
            
            VStack(spacing: 0) {
                // ヘッダー行
                HStack(spacing: 0) {
                    Text("機能・特典")
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("無料")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 70, alignment: .center)
                        .foregroundColor(.secondary)
                    
                    Text("Pro 👑")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 80, alignment: .center)
                        .foregroundColor(.purple)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.08))
                
                Divider()
                
                // 行データ
                let rows: [(String, String, String)] = [
                    ("登録枠上限", "最大10件", "無制限 ♾"),
                    ("スクショ自動解析", "月3回まで", "無制限 📸"),
                    ("リマインド通知", "1日前のみ", "複数回対応 ⏰"),
                    ("確定申告・経費CSV", "非対応 ❌", "書き出し対応 📄"),
                    ("テーマ＆アイコン", "非対応 ❌", "全解放 ✨")
                ]
                
                ForEach(0..<rows.count, id: \.self) { index in
                    let row = rows[index]
                    HStack(spacing: 0) {
                        Text(row.0)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(row.1)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .center)
                        
                        Text(row.2)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.purple)
                            .frame(width: 80, alignment: .center)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(index % 2 == 1 ? Color.secondary.opacity(0.03) : Color.clear)
                    
                    if index < rows.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}
