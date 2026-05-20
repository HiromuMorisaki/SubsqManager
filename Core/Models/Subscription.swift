//
//  Subscription.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// サブスクリプション情報を永続化するSwiftDataモデル。
///
/// SwiftDataの `@Model` マクロを付与すると、クラスのプロパティが自動的に
/// 永続化対象となる。CoreDataのNSManagedObjectに相当するが、
/// 純粋なSwiftクラスとして扱えるため学習コストが低い。
///
/// 注意: SwiftDataはDecimal型をネイティブサポートしていないため、
/// 内部的にはNSDecimalNumberとしてトランスフォームされて保存される。
@Model
final class Subscription {

    /// サブスク名（例: "Netflix", "Spotify"）
    var name: String

    /// 金額。Decimal型を使用し浮動小数点誤差を防止。
    /// SwiftDataはDecimalをNSDecimalNumberとしてブリッジして永続化する。
    var amount: Decimal

    /// 請求サイクル（週額/月額/年額）
    var billingCycle: BillingCycle

    /// カテゴリ（エンタメ/仕事/ライフスタイル/教育/その他）
    var category: Category

    /// サブスク開始日
    var startDate: Date

    /// 次回請求日（startDateとbillingCycleから自動計算、または手動設定）
    var nextPaymentDate: Date

    /// SF Symbol名（例: "tv", "music.note"）。UI上でアイコン表示に使用。
    var iconName: String

    /// メモ（任意入力）
    var notes: String

    /// 有効/無効フラグ。解約済みサブスクを非アクティブにして保持可能。
    var isActive: Bool

    /// レコード作成日時
    var createdAt: Date

    /// レコード更新日時
    var updatedAt: Date

    /// 指定イニシャライザ。
    /// createdAt / updatedAt は自動で現在日時を設定。
    /// nextPaymentDate はデフォルトで startDate と同じ値を設定（登録後に計算で上書き可能）。
    init(
        name: String,
        amount: Decimal,
        billingCycle: BillingCycle,
        category: Category,
        startDate: Date,
        nextPaymentDate: Date? = nil,
        iconName: String = "creditcard",
        notes: String = "",
        isActive: Bool = true
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.category = category
        self.startDate = startDate
        self.nextPaymentDate = nextPaymentDate ?? startDate
        self.iconName = iconName
        self.notes = notes
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 計算プロパティ

    /// 月額換算金額
    var monthlyAmount: Decimal {
        amount * billingCycle.monthlyMultiplier
    }

    /// 年額換算金額
    var yearlyAmount: Decimal {
        amount * billingCycle.yearlyMultiplier
    }
}
