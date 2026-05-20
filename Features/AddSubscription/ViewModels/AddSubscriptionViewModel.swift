//
//  AddSubscriptionViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// サブスク登録画面のViewModel。
/// フォーム入力の状態を保持し、バリデーションと保存ロジックを提供する。
///
/// ### 金額入力について
/// TextFieldはString型でしかバインドできないため、金額はStringで受け取り、
/// 保存時に Decimal(string:) で変換する。
/// Double を経由しないことで浮動小数点誤差を防いでいる。
@Observable
final class AddSubscriptionViewModel {

    // MARK: - フォーム状態

    var name: String = ""
    /// 金額の入力値（String）。保存時にDecimalへ変換する。
    var amountText: String = ""
    var billingCycle: BillingCycle = .monthly
    var category: Category = .other
    var startDate: Date = Date()
    var hasTrial: Bool = false
    var trialEndDate: Date = Date().addingTimeInterval(86400 * 14) // デフォルトで2週間後
    var hasEndDate: Bool = false
    var endDate: Date = Date().addingTimeInterval(86400 * 30) // デフォルト30日後
    var iconName: String = "creditcard"
    var notes: String = ""

    // MARK: - バリデーション

    /// フォームが有効かどうか。保存ボタンの有効/無効制御に使用。
    /// guard let で安全にDecimal変換を試み、失敗時はfalseを返す。
    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return true
    }

    // MARK: - プリセット適用

    /// 選択されたプリセットの値をフォームに反映する
    func applyPreset(_ preset: SubscriptionPreset) {
        self.name = preset.name
        self.amountText = NSDecimalNumber(decimal: preset.defaultAmount).stringValue
        self.category = preset.category
        self.iconName = preset.iconName
    }

    // MARK: - 保存

    /// フォームの入力内容からSubscriptionを生成し、SwiftDataに保存する。
    /// 保存後、請求日前日のリマインド通知をスケジュールする。
    /// - Parameter modelContext: View側の @Environment から渡されるModelContext
    /// - Returns: 保存成功ならtrue、バリデーション失敗ならfalse
    func save(using modelContext: ModelContext) async -> Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let subscription = Subscription(
            name: trimmedName,
            amount: amount,
            billingCycle: billingCycle,
            category: category,
            startDate: startDate,
            iconName: iconName,
            notes: notes.trimmingCharacters(in: .whitespaces),
            trialEndDate: hasTrial ? trialEndDate : nil,
            endDate: hasEndDate ? endDate : nil
        )

        // startDate と billingCycle から正しい次回請求日を計算
        subscription.updateNextPaymentDate()

        modelContext.insert(subscription)

        // 請求日前日のリマインド通知をスケジュール
        let notificationID = NotificationService.makeIdentifier(
            name: trimmedName, startDate: startDate
        )
        await NotificationService.scheduleReminder(
            subscriptionName: trimmedName,
            nextPaymentDate: subscription.nextPaymentDate,
            identifier: notificationID
        )

        // トライアルや終了日の設定がある場合はリマインド通知をスケジュール
        if subscription.trialEndDate != nil {
            await NotificationService.scheduleTrialReminder(
                subscriptionName: subscription.name,
                trialEndDate: subscription.trialEndDate!,
                identifier: notificationID + "_trial"
            )
        }
        if subscription.endDate != nil {
            await NotificationService.scheduleEndDateReminder(
                subscriptionName: subscription.name,
                endDate: subscription.endDate!,
                identifier: notificationID + "_end"
            )
        }

        return true
    }
}
