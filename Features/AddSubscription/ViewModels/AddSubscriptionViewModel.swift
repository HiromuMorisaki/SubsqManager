//
//  AddSubscriptionViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// サブスク登録画面のViewModel。
/// フォーム入力の状態を保持し、バリデーションと保存ロジックを提供する。
///
/// ### 金額入力について
/// TextFieldはString型でしかバインドできないため、金額はStringで受け取り、
/// 保存時に Decimal(string:) で変換する。
/// Double を経由しないことで浮動小数点誤差を防いでいる。
@Observable
final class AddSubscriptionViewModel {

    init() {}

    // MARK: - OCR 解析状態
    var isAnalyzingOCR: Bool = false
    @ObservationIgnored private let ocrService = OCRService()
    
    /// 一括インポーターで検出されたサブスクデータ
    var parsedBulkItems: [ParsedBulkItem] = []

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
    var satisfaction: Int = 0 // 0 means not set
    var usageFrequency: UsageFrequency = .notSet
    var isShared: Bool = false
    var splitCount: Int = 1
    var ownSharePercentage: Double = 1.0
    var paymentMethod: PaymentMethod = .notSet
    var isNotificationEnabled: Bool = true
    var isExpense: Bool = false
    var onSaveSuccess: (() -> Void)? = nil

    // MARK: - バリデーション

    /// フォームが有効かどうか。保存ボタンの有効/無効制御に使用。
    /// guard let で安全にDecimal変換を試み、失敗時はfalseを返す。
    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return true
    }

    // MARK: - プリセット適用

    /// 選択されたプリセットとプランの値をフォームに反映する
    func applyPreset(_ preset: SubscriptionPreset, plan: SubscriptionPlan) {
        // 例: "Netflix (プレミアム)" のようにプラン名を付与
        self.name = "\(preset.name) (\(plan.name))"
        self.amountText = NSDecimalNumber(decimal: plan.amount).stringValue
        self.billingCycle = plan.billingCycle
        self.category = preset.category
        self.iconName = preset.iconName
    }

    // MARK: - OCR 解析
    
    @MainActor
    func processScreenshot(imageData: Data) async {
        isAnalyzingOCR = true
        parsedBulkItems.removeAll() // リセット
        
        do {
            // 位置（Y座標）情報付きで画像からテキストを抽出
            let elements = try await ocrService.extractTextWithPositions(from: imageData)
            let fullText = elements.map { $0.text }.joined(separator: " ")
            
            // 「更新日」「有効期限」「更新予定」「有効期間」などのキーワードの出現回数をカウント
            let keywords = ["更新日", "有効期限", "更新予定", "有効期間"]
            var count = 0
            for keyword in keywords {
                let textToSearch = fullText
                var range = textToSearch.startIndex..<textToSearch.endIndex
                while let foundRange = textToSearch.range(of: keyword, options: .caseInsensitive, range: range) {
                    count += 1
                    range = foundRange.upperBound..<textToSearch.endIndex
                }
            }
            
            if count >= 2 {
                // 💡 複数検知（一括インポート）と判断！
                let bulkItems = ocrService.parseBulkSubscriptionInfo(from: elements)
                if !bulkItems.isEmpty {
                    self.parsedBulkItems = bulkItems
                }
            } else {
                // 💡 単一のサブスクスクショと判断し、従来通りパースしてフォームに適用
                let textLines = elements.map { $0.text }
                let result = ocrService.parseSubscriptionInfo(from: textLines)
                
                if let parsedName = result.name {
                    self.name = parsedName
                    if let preset = SubscriptionPreset.defaultPresets.first(where: { $0.name == parsedName }) {
                        self.category = preset.category
                        self.iconName = preset.iconName
                    }
                }
                if let parsedAmount = result.amount {
                    self.amountText = NSDecimalNumber(decimal: parsedAmount).stringValue
                }
                if let parsedCycle = result.billingCycle {
                    self.billingCycle = parsedCycle
                }
            }
            
            // AI自動入力・一括検知時はHaptic Feedbackを鳴らす
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            
        } catch {
            print("OCR Error: \(error)")
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
        
        isAnalyzingOCR = false
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
            endDate: hasEndDate ? endDate : nil,
            satisfaction: satisfaction,
            monthlyUsageCount: usageFrequency.monthlyEstimatedCount,
            usageFrequencyRawValue: usageFrequency.rawValue,
            isShared: isShared,
            splitCount: splitCount,
            ownSharePercentage: ownSharePercentage,
            paymentMethodRawValue: paymentMethod.rawValue,
            isNotificationEnabled: isNotificationEnabled,
            isExpense: isExpense
        )

        // startDate と billingCycle から正しい次回請求日を計算
        subscription.updateNextPaymentDate()

        modelContext.insert(subscription)

        // 通知が有効な場合のみスケジュールする
        if isNotificationEnabled {
            // 請求日前のリマインド通知をスケジュール
            let notificationID = NotificationService.makeIdentifier(
                name: trimmedName, startDate: startDate
            )
            
            let leadDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
            let actualLeadDays = leadDays > 0 ? leadDays : 1

            await NotificationService.scheduleReminder(
                subscriptionName: trimmedName,
                nextPaymentDate: subscription.nextPaymentDate,
                identifier: notificationID,
                leadDays: actualLeadDays
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
        }

        // カレンダー自動連携がONであれば、カレンダーイベントを登録する
        if UserDefaults.standard.bool(forKey: "calendarSyncEnabled") {
            await CalendarService.syncSubscription(subscription)
        }


        onSaveSuccess?()

        return true
    }

    /// フォームの入力内容をリセットする
    func reset() {
        self.name = ""
        self.amountText = ""
        self.billingCycle = .monthly
        self.category = .other
        self.startDate = Date()
        self.hasTrial = false
        self.trialEndDate = Date().addingTimeInterval(86400 * 14)
        self.hasEndDate = false
        self.endDate = Date().addingTimeInterval(86400 * 30)
        self.iconName = "creditcard"
        self.notes = ""
        self.satisfaction = 0
        self.usageFrequency = .notSet
        self.isShared = false
        self.splitCount = 1
        self.ownSharePercentage = 1.0
        self.paymentMethod = .notSet
        self.isNotificationEnabled = true
        self.isExpense = false
        self.onSaveSuccess = nil
    }
}
