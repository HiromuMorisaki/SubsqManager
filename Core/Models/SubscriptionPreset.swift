//
//  SubscriptionPreset.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// サブスク登録時のプリセット入力用データ構造
struct SubscriptionPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let defaultAmount: Decimal
    let category: Category
    let iconName: String
    
    // 代表的なサブスクのプリセットリスト
    static let defaultPresets: [SubscriptionPreset] = [
        SubscriptionPreset(name: "Netflix", defaultAmount: 1490, category: .entertainment, iconName: "film"),
        SubscriptionPreset(name: "Spotify", defaultAmount: 980, category: .entertainment, iconName: "music.note"),
        SubscriptionPreset(name: "Amazon Prime", defaultAmount: 600, category: .lifestyle, iconName: "cart"),
        SubscriptionPreset(name: "YouTube Premium", defaultAmount: 1280, category: .entertainment, iconName: "play.rectangle"),
        SubscriptionPreset(name: "iCloud+", defaultAmount: 130, category: .other, iconName: "cloud"),
        SubscriptionPreset(name: "Apple Music", defaultAmount: 1080, category: .entertainment, iconName: "applelogo"),
        SubscriptionPreset(name: "Disney+", defaultAmount: 990, category: .entertainment, iconName: "sparkles.tv"),
        SubscriptionPreset(name: "Adobe CC", defaultAmount: 6480, category: .work, iconName: "paintbrush.pointed")
    ]
}
