//
//  CurrencyHelper.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// 通貨フォーマットの共通ヘルパー。
/// UserDefaults に保存された通貨コードを読み取り、
/// Decimal をローカライズされた通貨文字列にフォーマットする。
///
/// ### 使い方
/// ```swift
/// let formatted = CurrencyHelper.formatted(amount: Decimal(980))
/// // → "¥980"（JPY選択時）/ "$980.00"（USD選択時）
/// ```
enum CurrencyHelper {

    /// UserDefaults から通貨コードを取得する。
    /// SettingsView の @AppStorage("currencyCode") と同じキーを参照。
    static var currentCurrencyCode: String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? "JPY"
    }

    /// Decimal 金額を現在の通貨設定でフォーマットする。
    /// - Parameter amount: フォーマットする金額
    /// - Returns: 通貨記号付きのフォーマット済み文字列
    static func formatted(amount: Decimal) -> String {
        amount.formatted(.currency(code: currentCurrencyCode))
    }
}
