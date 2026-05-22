//
//  UsageFrequency.swift
//  SubsqManager
//
//  Created by Antigravity on 2026/05/22.
//

import Foundation

/// サブスクリプションの利用頻度を表す段階的Enum
enum UsageFrequency: String, Codable, CaseIterable, Identifiable {
    case never = "never"         // 使っていない (月0回)
    case rarely = "rarely"       // たまに使う (月1回)
    case sometimes = "sometimes" // ときどき使う (月2〜3回)
    case often = "often"         // よく使う (週2〜3回)
    case veryOften = "veryOften" // 頻繁に使う (週5回以上)
    case daily = "daily"         // ほぼ毎日

    var id: String { rawValue }

    /// 画面に表示する名称
    var displayName: String {
        switch self {
        case .never:
            return "使っていない (月0回)"
        case .rarely:
            return "たまに使う (月1回)"
        case .sometimes:
            return "ときどき使う (月2〜3回)"
        case .often:
            return "よく使う (週2〜3回)"
        case .veryOften:
            return "頻繁に使う (週5回以上)"
        case .daily:
            return "ほぼ毎日"
        }
    }

    /// コスパ診断等の計算に利用する、月間換算の推定利用回数
    var monthlyEstimatedCount: Int {
        switch self {
        case .never: return 0
        case .rarely: return 1
        case .sometimes: return 3
        case .often: return 10
        case .veryOften: return 22
        case .daily: return 30
        }
    }

    /// 数値（月間利用回数）から最も適したUsageFrequencyを返すファクトリメソッド
    static func from(monthlyUsageCount count: Int) -> UsageFrequency {
        if count <= 0 {
            return .never
        } else if count == 1 {
            return .rarely
        } else if count <= 5 {
            return .sometimes
        } else if count <= 15 {
            return .often
        } else if count <= 25 {
            return .veryOften
        } else {
            return .daily
        }
    }
}
