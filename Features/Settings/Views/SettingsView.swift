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

    /// 選択中の通貨コード（UserDefaultsに永続化）
    @AppStorage("currencyCode") private var currencyCode = "JPY"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                currencySection
                dataSection
                helpSection
                appInfoSection
            }
            .navigationTitle("設定")
        }
    }

    // MARK: - セクション

    /// 通知設定セクション
    private var notificationSection: some View {
        Section {
            Toggle("請求日リマインド", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    Task {
                        if newValue {
                            // ON: 全サブスクの通知を一括スケジュール
                            for subscription in subscriptions where subscription.isActive {
                                let id = NotificationService.makeIdentifier(
                                    name: subscription.name, startDate: subscription.startDate
                                )
                                await NotificationService.scheduleReminder(
                                    subscriptionName: subscription.name,
                                    nextPaymentDate: subscription.nextPaymentDate,
                                    identifier: id
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
                            // OFF: 全通知をキャンセル
                            NotificationService.cancelAllReminders()
                        }
                    }
                }
        } header: {
            Label("通知", systemImage: "bell")
        } footer: {
            Text("ONにすると、請求日の前日に通知でお知らせします")
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
}

// MARK: - Preview

#Preview {
    SettingsView()
}
