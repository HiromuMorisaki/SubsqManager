//
//  ReductionHistory.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/21.
//

import Foundation
import SwiftData

@Model
final class ReductionHistory {
    /// 削減したサービス名
    var name: String = ""

    /// 削減された金額
    var amount: Decimal = 0

    /// 削減時の請求サイクル
    var billingCycleRawValue: String = BillingCycle.monthly.rawValue

    /// 削減時のカテゴリ
    var categoryRawValue: String = Category.other.rawValue

    /// 解約日（削減した日）
    var cancelledDate: Date = Date()

    /// SF Symbol名
    var iconName: String = "creditcard"

    /// 解約時のメモ（元のメモなどを残せるようにする）
    var originalMemo: String?

    /// 通貨コード（将来の多通貨対応用、デフォルトは"JPY"）
    var currencyCode: String = "JPY"

    /// レコード作成日時
    var createdAt: Date = Date()

    init(
        name: String,
        amount: Decimal,
        billingCycle: BillingCycle,
        category: Category,
        cancelledDate: Date = Date(),
        iconName: String = "creditcard",
        originalMemo: String? = nil,
        currencyCode: String = "JPY"
    ) {
        self.name = name
        self.amount = amount
        self.billingCycleRawValue = billingCycle.rawValue
        self.categoryRawValue = category.rawValue
        self.cancelledDate = cancelledDate
        self.iconName = iconName
        self.originalMemo = originalMemo
        self.currencyCode = currencyCode
        self.createdAt = Date()
    }

    // MARK: - 計算プロパティ

    var billingCycle: BillingCycle {
        BillingCycle(rawValue: billingCycleRawValue) ?? .monthly
    }

    var category: Category {
        Category(rawValue: categoryRawValue) ?? .other
    }

    /// 月額換算された削減額
    var monthlyAmount: Decimal {
        amount * billingCycle.monthlyMultiplier
    }

    /// 年額換算された削減額
    var yearlyAmount: Decimal {
        amount * billingCycle.yearlyMultiplier
    }
}
