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
    case music         = "music"
    case manga         = "manga"
    case sports        = "sports"
    case game          = "game"
    case kids          = "kids"
    case fanclub       = "fanclub"
    case education     = "education"
    case work          = "work"
    case ai            = "ai"
    case news          = "news"
    case cloud         = "cloud"
    case security      = "security"
    case healthcare    = "healthcare"
    case food          = "food"
    case financial     = "financial"
    case lifestyle     = "lifestyle"
    case lessons       = "lessons"
    case other         = "other"

    var id: String { rawValue }

    /// UI表示用のラベル
    var displayName: String {
        switch self {
        case .entertainment: return "動画・エンタメ"
        case .music:         return "音楽"
        case .manga:         return "マンガ・電子書籍"
        case .sports:        return "スポーツ"
        case .game:          return "ゲーム"
        case .kids:          return "子育て・キッズ"
        case .fanclub:       return "ファンクラブ"
        case .education:     return "学習・教育"
        case .work:          return "仕事・制作"
        case .ai:            return "生成AI"
        case .news:          return "ニュース・読書"
        case .cloud:         return "クラウド"
        case .security:      return "セキュリティ"
        case .healthcare:    return "ヘルスケア"
        case .food:          return "フード・宅配"
        case .financial:     return "ファイナンス"
        case .lifestyle:     return "ライフスタイル"
        case .lessons:       return "習い事・教室"
        case .other:         return "その他"
        }
    }

    /// カテゴリに対応するSF Symbolアイコン名
    var iconName: String {
        switch self {
        case .entertainment: return "tv"
        case .music:         return "music.note"
        case .manga:         return "book.closed"
        case .sports:        return "sportscourt"
        case .game:          return "gamecontroller"
        case .kids:          return "figure.2.and.child.holdinghands"
        case .fanclub:       return "star.circle"
        case .education:     return "graduationcap"
        case .work:          return "briefcase"
        case .ai:            return "sparkles"
        case .news:          return "newspaper"
        case .cloud:         return "cloud"
        case .security:      return "lock.shield"
        case .healthcare:    return "heart.text.square"
        case .food:          return "fork.knife.circle"
        case .financial:     return "yensign.circle"
        case .lifestyle:     return "cart"
        case .lessons:       return "figure.run"
        case .other:         return "ellipsis.circle"
        }
    }

    /// カテゴリのテーマカラー
    var color: Color {
        switch self {
        case .entertainment: return .purple
        case .music:         return .teal
        case .manga:         return .orange
        case .sports:        return .green
        case .game:          return .red
        case .kids:          return .yellow
        case .fanclub:       return .pink
        case .education:     return .mint
        case .work:          return .blue
        case .ai:            return .cyan
        case .news:          return Color(.brown)
        case .cloud:         return .blue
        case .security:      return .indigo
        case .healthcare:    return .pink
        case .food:          return .red
        case .financial:     return .green
        case .lifestyle:     return .orange
        case .lessons:       return .indigo
        case .other:         return .gray
        }
    }
}
