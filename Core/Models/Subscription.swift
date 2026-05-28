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
    var name: String = ""

    /// 金額。Decimal型を使用し浮動小数点誤差を防止。
    /// SwiftDataはDecimalをNSDecimalNumberとしてブリッジして永続化する。
    var amount: Decimal = 0

    /// 請求サイクル（週額/月額/年額）
    var billingCycle: BillingCycle = BillingCycle.monthly

    /// カテゴリ（エンタメ/仕事/ライフスタイル/教育/その他）
    var category: Category = Category.other

    /// サブスク開始日
    var startDate: Date = Date()

    /// 次回請求日（startDateとbillingCycleから自動計算、または手動設定）
    var nextPaymentDate: Date = Date()

    /// SF Symbol名（例: "tv", "music.note"）。UI上でアイコン表示に使用。
    var iconName: String = "creditcard"

    /// メモ（任意入力）
    var notes: String = ""

    /// 有効/無効フラグ。解約済みサブスクを非アクティブにして保持可能。
    var isActive: Bool = true

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

    /// 仕事用・経費かどうかのフラグ
    var isExpense: Bool = false

    /// カレンダーの通常請求リマインダイベントID
    var calendarEventIdentifier: String?

    /// カレンダーの無料トライアル終了リマインダイベントID
    var trialCalendarEventIdentifier: String?

    /// レコード作成日時
    var createdAt: Date = Date()

    /// レコード更新日時
    var updatedAt: Date = Date()

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
        satisfaction: Int = 0,
        monthlyUsageCount: Int = -1,
        usageFrequencyRawValue: String = UsageFrequency.notSet.rawValue,
        isShared: Bool = false,
        splitCount: Int = 1,
        ownSharePercentage: Double = 1.0,
        paymentMethodRawValue: String? = nil,
        isNotificationEnabled: Bool = true,
        isExpense: Bool = false,
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
        if let freq = UsageFrequency(rawValue: usageFrequencyRawValue) {
            self.monthlyUsageCount = freq.monthlyEstimatedCount
        } else {
            self.monthlyUsageCount = monthlyUsageCount
        }
        self.isShared = isShared
        self.splitCount = splitCount
        self.ownSharePercentage = ownSharePercentage
        if let initialPaymentMethod = paymentMethodRawValue as String? {
            self.paymentMethodRawValue = initialPaymentMethod
        }
        self.isNotificationEnabled = isNotificationEnabled
        self.isExpense = isExpense
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

enum ExpenseFilter: String, CaseIterable, Identifiable, Codable {
    case all = "すべて"
    case privateOnly = "プライベート"
    case expenseOnly = "経費・仕事用"
    var id: String { rawValue }
}

// MARK: - ProManager

import StoreKit
import Observation

/// アプリのPro機能ロック解除ステータスを統合管理するサービス。
/// iOS 17以降の `@Observable` マクロを採用し、SwiftUIビューからリアクティブに状態を購読できる。
@Observable
final class ProManager {
    
    static let shared = ProManager()
    
    /// Proプランの購入済みステータス。
    /// 内部的には UserDefaults で永続化し、ビューへの通知も `@Observable` でシームレスに行う。
    private(set) var isProUnlocked: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isProUnlocked")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isProUnlocked")
        }
    }
    
    /// StoreKitの監視タスク保持用
    private var transactionListenerTask: Task<Void, Error>?
    
    private init() {
        // アプリ起動時に購入状況のアップデートとStoreKitトランザクションのリスナーを開始
        startTransactionListener()
        Task {
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    /// 【デバッグ・開発用】Proプランのステータスを手動で切り替える（テスト用裏機能）
    func debugToggleProStatus() {
        #if DEBUG
        isProUnlocked.toggle()
        print("Pro Status Toggled manually to: \(isProUnlocked)")
        #endif
    }
    
    /// 購入状態を手動でシミュレートする（StoreKit実装前の確認用）
    func unlockProManually() {
        isProUnlocked = true
    }
    
    /// 購入状態をリセットする
    func lockProManually() {
        isProUnlocked = false
    }
    
    // MARK: - StoreKit 2 実装 (骨組みとトランザクション監視)
    
    /// StoreKit 2 のアクティブなトランザクションをリッスンし、リアルタイムでの購入・払い戻しに追従する。
    func startTransactionListener() {
        transactionListenerTask = Task.detached(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // トランザクションが検証されたら、Proステータスを有効にする
                    await MainActor.run {
                        self.isProUnlocked = true
                    }
                    
                    // App Store にトランザクションの処理完了を通知
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    /// 既に購入済みのアイテム（アクティブなサブスクや買い切り）があるか確認し、ステータスを復元する
    func updatePurchasedProducts() async {
        var hasActivePro = false
        
        // 現在アクティブなエンタイトルメント（購入済み商品）をスキャン
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // コテサクProのプロダクトID群（想定）
                if transaction.productID.contains("SubsqManager.pro") || transaction.productID.contains("pro_") {
                    // 有効なトランザクションがある場合
                    hasActivePro = true
                }
            } catch {
                print("Failed to verify transaction entitlement: \(error)")
            }
        }
        
        // 開発環境かつStoreKitテスト構成がない場合は、UserDefaultsの値を尊重
        #if DEBUG
        // DEBUG環境下では手動でのON/OFF切り替えを阻害しないよう、
        // もしアクティブなトランザクションが実際に検知された場合のみ上書きする
        if hasActivePro {
            await MainActor.run {
                self.isProUnlocked = true
            }
        }
        #else
        // 本番環境では実トランザクションの状態を同期
        await MainActor.run {
            self.isProUnlocked = hasActivePro
        }
        #endif
    }
    
    /// StoreKitのトランザクション検証処理
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // 署名検証に失敗した場合
            throw error
        case .verified(let safe):
            // 署名が正しく検証された場合
            return safe
        }
    }
}
