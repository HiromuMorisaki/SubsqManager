//
//  BillingCycle.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// サブスクリプションの請求サイクルを表すenum。
/// SwiftDataの@Modelプロパティとして使用するため、Codableに準拠。
/// CaseIterableにより、ピッカー等でenum全ケースをループ表示可能。
enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case oneTime = "oneTime"

    var id: String { rawValue }

    /// UI表示用のラベル
    var displayName: String {
        switch self {
        case .weekly: return "週額"
        case .monthly: return "月額"
        case .yearly: return "年額"
        case .oneTime: return "1度きり"
        }
    }

    /// 月額換算の係数。ダッシュボードで月額合計を計算する際に使用。
    /// 例: weekly → 1週間あたりの金額 × (52/12) ≈ 4.333... で月額に変換
    var monthlyMultiplier: Decimal {
        switch self {
        case .weekly: return Decimal(52) / Decimal(12)
        case .monthly: return Decimal(1)
        case .yearly: return Decimal(1) / Decimal(12)
        case .oneTime: return Decimal(0)
        }
    }

    /// 年額換算の係数
    var yearlyMultiplier: Decimal {
        switch self {
        case .weekly: return Decimal(52)
        case .monthly: return Decimal(12)
        case .yearly: return Decimal(1)
        case .oneTime: return Decimal(0)
        }
    }
}
