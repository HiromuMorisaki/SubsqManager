//
//  EditSubscriptionViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// サブスク編集画面のViewModel。
/// 既存の Subscription を受け取り、フォームの初期値をセット。
/// 保存時は新規作成ではなく、既存オブジェクトのプロパティを直接更新する。
@Observable
final class EditSubscriptionViewModel {

    // MARK: - フォーム状態

    var name: String
    var amountText: String
    var billingCycle: BillingCycle
    var category: Category
    var startDate: Date
    var hasTrial: Bool
    var trialEndDate: Date
    var hasEndDate: Bool
    var endDate: Date
    var iconName: String
    var notes: String
    var satisfaction: Int
    var usageFrequency: UsageFrequency
    var isShared: Bool
    var splitCount: Int
    var ownSharePercentage: Double
    var paymentMethod: PaymentMethod
    var isNotificationEnabled: Bool

    /// 編集対象のサブスクリプション（参照を保持）
    private let subscription: Subscription

    /// 通知IDの生成に必要な元の名前と開始日（変更前の値で旧通知をキャンセルするため）
    private let originalName: String
    private let originalStartDate: Date

    // MARK: - 初期化

    /// 既存の Subscription からフォームの初期値をセットする。
    /// Decimal → String 変換には NSDecimalNumber.stringValue を使用し、
    /// 浮動小数点の丸め誤差を回避する。
    init(subscription: Subscription) {
        self.subscription = subscription
        self.name = subscription.name
        self.amountText = NSDecimalNumber(decimal: subscription.amount).stringValue
        self.billingCycle = subscription.billingCycle
        self.category = subscription.category
        self.startDate = subscription.startDate
        self.hasTrial = subscription.trialEndDate != nil
        self.trialEndDate = subscription.trialEndDate ?? Date().addingTimeInterval(86400 * 14)
        self.hasEndDate = subscription.endDate != nil
        self.endDate = subscription.endDate ?? Date().addingTimeInterval(86400 * 30)
        self.iconName = subscription.iconName
        self.notes = subscription.notes
        self.satisfaction = subscription.satisfaction
        self.usageFrequency = subscription.usageFrequency
        self.isShared = subscription.isShared
        self.splitCount = subscription.splitCount
        self.ownSharePercentage = subscription.ownSharePercentage
        self.paymentMethod = subscription.paymentMethod
        self.isNotificationEnabled = subscription.isNotificationEnabled
        self.originalName = subscription.name
        self.originalStartDate = subscription.startDate
    }

    // MARK: - バリデーション

    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return true
    }

    // MARK: - 保存

    /// 既存の Subscription のプロパティを更新する。
    /// 新規作成（insert）ではなく、SwiftData オブジェクトのプロパティを
    /// 直接書き換えることで更新が永続化される。
    func save() async -> Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        // 既存オブジェクトのプロパティを直接更新
        subscription.name = trimmedName
        subscription.amount = amount
        subscription.billingCycle = billingCycle
        subscription.category = category
        subscription.startDate = startDate
        subscription.iconName = iconName
        subscription.notes = notes.trimmingCharacters(in: .whitespaces)
        subscription.trialEndDate = hasTrial ? trialEndDate : nil
        subscription.endDate = hasEndDate ? endDate : nil
        subscription.satisfaction = satisfaction
        subscription.usageFrequency = usageFrequency
        subscription.isShared = isShared
        subscription.splitCount = splitCount
        subscription.ownSharePercentage = ownSharePercentage
        subscription.paymentMethod = paymentMethod
        subscription.isNotificationEnabled = isNotificationEnabled
        subscription.updateNextPaymentDate()

        // 旧通知をキャンセル
        let oldNotificationID = NotificationService.makeIdentifier(
            name: originalName, startDate: originalStartDate
        )
        NotificationService.cancelReminder(identifier: oldNotificationID)
        let oldTrialNotificationID = oldNotificationID + "_trial"
        NotificationService.cancelReminder(identifier: oldTrialNotificationID)
        let oldEndDateNotificationID = oldNotificationID + "_end"
        NotificationService.cancelReminder(identifier: oldEndDateNotificationID)

        if isNotificationEnabled {
            // 新しい通知をスケジュール
            let newNotificationID = NotificationService.makeIdentifier(
                name: trimmedName, startDate: startDate
            )
            
            let leadDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
            let actualLeadDays = leadDays > 0 ? leadDays : 1

            await NotificationService.scheduleReminder(
                subscriptionName: trimmedName,
                nextPaymentDate: subscription.nextPaymentDate,
                identifier: newNotificationID,
                leadDays: actualLeadDays
            )

            // 新しいトライアル通知をスケジュール
            if hasTrial {
                let trialNotificationID = newNotificationID + "_trial"
                await NotificationService.scheduleTrialReminder(
                    subscriptionName: trimmedName,
                    trialEndDate: trialEndDate,
                    identifier: trialNotificationID
                )
            }
            
            // 新しい終了日通知をスケジュール
            if hasEndDate {
                let endDateNotificationID = newNotificationID + "_end"
                await NotificationService.scheduleEndDateReminder(
                    subscriptionName: trimmedName,
                    endDate: endDate,
                    identifier: endDateNotificationID
                )
            }
        }

        // カレンダー自動連携がONであれば、カレンダーイベントを更新（同期）する
        if UserDefaults.standard.bool(forKey: "calendarSyncEnabled") {
            await CalendarService.syncSubscription(subscription)
        }

        return true
    }
}
