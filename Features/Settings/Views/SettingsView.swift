//
//  SettingsView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// 設定画面。通知ON/OFF、通貨選択、アプリ情報を表示する。
///
/// ### @AppStorage について
/// UserDefaultsの値をSwiftUIのプロパティとしてバインドする仕組み。
/// 値を変更すると自動的にUserDefaultsに保存され、アプリ再起動後も保持される。
/// @State と同様にViewの再描画もトリガーする。
struct SettingsView: View {
    @Query private var subscriptions: [Subscription]
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

    @State private var isSyncing = false
    @State private var showingSyncSuccessAlert = false
    @State private var showingSyncErrorAlert = false
    @State private var alertMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                calendarSection
                currencySection
                dataSection
                helpSection
                appInfoSection
            }
            .navigationTitle("設定")
            .alert("完了", isPresented: $showingSyncSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("エラー", isPresented: $showingSyncErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - セクション

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
                Button {
                    syncAllToCalendar()
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
            Text("有効にすると、サブスクの次回請求日や無料トライアル終了日が自動的にiOS標準カレンダーに登録されます。")
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
            Button {
                showingOnboarding = true
            } label: {
                HStack {
                    Label("アプリの使い方を見る", systemImage: "questionmark.circle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            // ご意見・お問い合わせ
            Button {
                openMailApp()
            } label: {
                HStack {
                    Label("ご意見・お問い合わせ", systemImage: "envelope")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            // プライバシーポリシー
            if let url = URL(string: "https://kotesaku.notion.site/e2df7871a2394136ad71216a272eb0bb") {
                Link(destination: url) {
                    HStack {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
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
        Task {
            if enabled {
                let authorized = await CalendarService.requestAuthorization()
                if authorized {
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
                alertMessage = "カレンダーの同期設定をオフにし、登録されたすべてのイベントを削除しました。"
                showingSyncSuccessAlert = true
            }
        }
    }

    /// カレンダーへの一括サイレント同期
    private func syncAllToCalendarSilently() async {
        guard CalendarService.isAuthorized else { return }
        await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
    }

    /// 既存データをカレンダーに一括同期する（インジケータ表示付き）
    private func syncAllToCalendar() {
        Task {
            isSyncing = true
            let authorized = await CalendarService.requestAuthorization()
            if authorized {
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

// MARK: - Preview

#Preview {
    SettingsView()
}
