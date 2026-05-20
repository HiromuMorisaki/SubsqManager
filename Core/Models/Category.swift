//
//  Category.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftUI

/// サブスクリプションのカテゴリを表すenum。
/// 一覧画面でのグループ表示やフィルタリングに使用。
enum Category: String, Codable, CaseIterable, Identifiable {
    case entertainment = "entertainment"
    case work = "work"
    case lifestyle = "lifestyle"
    case game = "game"
    case healthcare = "healthcare"
    case financial = "financial"
    case education = "education"
    case ai = "ai"
    case other = "other"

    var id: String { rawValue }

    /// UI表示用のラベル
    var displayName: String {
        switch self {
        case .entertainment: return "エンタメ"
        case .work: return "仕事"
        case .lifestyle: return "ライフスタイル"
        case .game: return "ゲーム"
        case .healthcare: return "ヘルスケア"
        case .financial: return "ファイナンス"
        case .education: return "教育"
        case .ai: return "生成AI"
        case .other: return "その他"
        }
    }

    /// カテゴリに対応するSF Symbolアイコン名
    var iconName: String {
        switch self {
        case .entertainment: return "tv"
        case .work: return "briefcase"
        case .lifestyle: return "cart"
        case .game: return "gamecontroller"
        case .healthcare: return "heart.text.square"
        case .financial: return "yensign.circle"
        case .education: return "book"
        case .ai: return "sparkles"
        case .other: return "ellipsis.circle"
        }
    }

    /// カテゴリのテーマカラー
    var color: Color {
        switch self {
        case .entertainment: return .purple
        case .work: return .blue
        case .lifestyle: return .orange
        case .game: return .red
        case .healthcare: return .pink
        case .financial: return .green
        case .education: return .mint
        case .ai: return .cyan
        case .other: return .gray
        }
    }
}
