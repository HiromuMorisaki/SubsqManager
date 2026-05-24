//
//  Subscription.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// サブスク見直し（オーディット）でのステータス
enum ReviewStatus: String, Codable {
    case keep = "keep"
    case changePlan = "changePlan"
    case cancelCandidate = "cancelCandidate"
}

/// 支払い方法（サブスクの引き落とし元）
enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case creditCard = "クレジットカード"
    case appleID = "Apple ID"
    case googlePlay = "Google Play"
    case carrier = "キャリア決済"
    case bankTransfer = "銀行口座振替"
    case cash = "現金"
    case other = "その他"
    case notSet = "未設定"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .creditCard: return "creditcard"
        case .appleID: return "apple.logo"
        case .googlePlay: return "play.rectangle"
        case .carrier: return "iphone"
        case .bankTransfer: return "building.columns"
        case .cash: return "yensign.circle"
        case .other: return "ellipsis.circle"
        case .notSet: return "questionmark.circle"
        }
    }
}

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

    /// 見直し（オーディット）のステータス保存用
    var reviewStatusRawValue: String?

    /// 無料トライアル終了日。nilの場合はトライアルなし。
    var trialEndDate: Date?

    /// サブスクリプション終了予定日。nilの場合は未定（継続）。
    var endDate: Date?

    /// 満足度（1〜5段階、デフォルト3）
    var satisfaction: Int = 3

    /// 月の利用回数（デフォルト0）
    var monthlyUsageCount: Int = 0

    /// 利用頻度の段階設定値（生値）
    var usageFrequencyRawValue: String?

    /// 割り勘サブスクかどうかのフラグ
    var isShared: Bool = false

    /// 割り勘人数
    var splitCount: Int = 1

    /// 自己負担割合（0.0 〜 1.0）
    var ownSharePercentage: Double = 1.0

    /// 支払い方法（生値）
    var paymentMethodRawValue: String = PaymentMethod.notSet.rawValue

    /// 更新前のリマインド通知を有効にするかどうか
    var isNotificationEnabled: Bool = true

    /// カレンダーの通常請求リマインダイベントID
    var calendarEventIdentifier: String?

    /// カレンダーの無料トライアル終了リマインダイベントID
    var trialCalendarEventIdentifier: String?

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
        isActive: Bool = true,
        trialEndDate: Date? = nil,
        endDate: Date? = nil,
        reviewStatusRawValue: String? = nil,
        satisfaction: Int = 3,
        monthlyUsageCount: Int = 0,
        usageFrequencyRawValue: String? = nil,
        isShared: Bool = false,
        splitCount: Int = 1,
        ownSharePercentage: Double = 1.0,
        paymentMethodRawValue: String? = nil,
        isNotificationEnabled: Bool = true,
        calendarEventIdentifier: String? = nil,
        trialCalendarEventIdentifier: String? = nil
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
        self.trialEndDate = trialEndDate
        self.endDate = endDate
        self.reviewStatusRawValue = reviewStatusRawValue
        self.satisfaction = satisfaction
        self.usageFrequencyRawValue = usageFrequencyRawValue
        if let raw = usageFrequencyRawValue, let freq = UsageFrequency(rawValue: raw) {
            self.monthlyUsageCount = freq.monthlyEstimatedCount
        } else {
            self.monthlyUsageCount = monthlyUsageCount
        }
        self.isShared = isShared
        self.splitCount = splitCount
        self.ownSharePercentage = ownSharePercentage
        if let pmRaw = paymentMethodRawValue {
            self.paymentMethodRawValue = pmRaw
        }
        self.isNotificationEnabled = isNotificationEnabled
        self.calendarEventIdentifier = calendarEventIdentifier
        self.trialCalendarEventIdentifier = trialCalendarEventIdentifier
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 計算プロパティ

    /// 自己負担額 (実質負担額)
    var ownShareAmount: Decimal {
        if isShared {
            return amount * Decimal(ownSharePercentage)
        } else {
            return amount
        }
    }

    /// 自己負担の月額換算金額
    var ownShareMonthlyAmount: Decimal {
        ownShareAmount * billingCycle.monthlyMultiplier
    }

    /// 自己負担の年額換算金額
    var ownShareYearlyAmount: Decimal {
        ownShareAmount * billingCycle.yearlyMultiplier
    }

    /// 支払い方法（Enum）へのアクセス用プロパティ
    var paymentMethod: PaymentMethod {
        get {
            PaymentMethod(rawValue: paymentMethodRawValue) ?? .notSet
        }
        set {
            paymentMethodRawValue = newValue.rawValue
        }
    }

    /// レビュー状態（enum）へのアクセス用プロパティ
    var reviewStatus: ReviewStatus? {
        get {
            guard let rawValue = reviewStatusRawValue else { return nil }
            return ReviewStatus(rawValue: rawValue)
        }
        set {
            reviewStatusRawValue = newValue?.rawValue
        }
    }

    /// 利用頻度（Enum）へのアクセス用プロパティ。既存の `monthlyUsageCount` と相互補完マッピング
    var usageFrequency: UsageFrequency {
        get {
            if let rawValue = usageFrequencyRawValue, let freq = UsageFrequency(rawValue: rawValue) {
                return freq
            }
            return UsageFrequency.from(monthlyUsageCount: monthlyUsageCount)
        }
        set {
            usageFrequencyRawValue = newValue.rawValue
            monthlyUsageCount = newValue.monthlyEstimatedCount
        }
    }

    /// 現在無料トライアル中かどうか。
    /// trialEndDate が設定されており、かつ現在日時が trialEndDate の日の終わり（23:59:59）以前であれば true。
    var isTrial: Bool {
        guard let trialEndDate = trialEndDate else { return false }
        
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: trialEndDate).addingTimeInterval(86400 - 1)
        
        return Date() <= endOfDay
    }
    
    /// サブスクリプションが既に終了日を過ぎているかどうか。
    /// endDate が設定されており、現在日時が endDate の日の終わりを過ぎていれば true。
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: endDate).addingTimeInterval(86400 - 1)
        
        return Date() > endOfDay
    }

    /// 月額換算金額
    var monthlyAmount: Decimal {
        amount * billingCycle.monthlyMultiplier
    }

    /// 年額換算金額
    var yearlyAmount: Decimal {
        amount * billingCycle.yearlyMultiplier
    }

    // MARK: - メソッド

    /// PaymentDateCalculator を使って nextPaymentDate を現在日時以降の
    /// 最も近い請求日に更新する。startDate と billingCycle から自動計算。
    func updateNextPaymentDate() {
        nextPaymentDate = PaymentDateCalculator.nextPaymentDate(
            startDate: startDate,
            billingCycle: billingCycle
        )
        updatedAt = Date()
    }
}
