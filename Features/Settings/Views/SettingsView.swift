//
//  SettingsView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// 設定画面。通知ON/OFF、通貨選択、アプリ情報を表示する。
///
/// ### @AppStorage について
/// UserDefaultsの値をSwiftUIのプロパティとしてバインドする仕組み。
/// 値を変更すると自動的にUserDefaultsに保存され、アプリ再起動後も保持される。
/// @State と同様にViewの再描画もトリガーする。
struct SettingsView: View {

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
