//
//  Category.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// サブスクリプションのカテゴリを表すenum。
/// 一覧画面でのグループ表示やフィルタリングに使用。
enum Category: String, Codable, CaseIterable, Identifiable {
    case entertainment = "entertainment"
    case work = "work"
    case lifestyle = "lifestyle"
    case education = "education"
    case other = "other"

    var id: String { rawValue }

    /// UI表示用のラベル
    var displayName: String {
        switch self {
        case .entertainment: return "エンタメ"
        case .work: return "仕事"
        case .lifestyle: return "ライフスタイル"
        case .education: return "教育"
        case .other: return "その他"
        }
    }

    /// カテゴリに対応するSF Symbolアイコン名
    var iconName: String {
        switch self {
        case .entertainment: return "tv"
        case .work: return "briefcase"
        case .lifestyle: return "heart"
        case .education: return "book"
        case .other: return "ellipsis.circle"
        }
    }
}
