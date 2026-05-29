//
//  SubscriptionPreset.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// サブスクの料金プラン（JSON対応）
struct SubscriptionPlan: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let amount: Decimal
    let billingCycle: BillingCycle
}

/// サブスク登録時のプリセット入力用データ構造（JSON対応）
struct SubscriptionPreset: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: Category
    let iconName: String
    let plans: [SubscriptionPlan]
}

/// JSONファイルのルートコンテナ
struct PresetData: Codable {
    let version: String
    let lastUpdated: String
    let presets: [SubscriptionPreset]
}

/// バンドル内のJSONからプリセットを読み込むローダー
enum PresetLoader {
    /// アプリ起動時に1回だけJSONを読み込み、以降はキャッシュを返す
    static let shared: [SubscriptionPreset] = {
        guard let url = Bundle.main.url(forResource: "subscription_presets", withExtension: "json") else {
            print("⚠️ subscription_presets.json が見つかりません")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let presetData = try decoder.decode(PresetData.self, from: data)
            print("✅ プリセット読み込み完了: \(presetData.presets.count)件 (v\(presetData.version))")
            return presetData.presets
        } catch {
            print("⚠️ プリセットJSON読み込みエラー: \(error)")
            return []
        }
    }()
}

// MARK: - 互換性維持（既存コードからの参照をそのまま使えるようにする）
extension SubscriptionPreset {
    /// 代表的なサブスクのプリセットリスト（JSONから読み込み、300件以上）
    static let defaultPresets: [SubscriptionPreset] = PresetLoader.shared

    /// カテゴリごとにプリセットをグループ化した辞書を返す
    static var groupedByCategory: [Category: [SubscriptionPreset]] {
        Dictionary(grouping: defaultPresets, by: { $0.category })
    }
}
