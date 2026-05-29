//
//  NotificationService.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import UserNotifications

/// ローカル通知の管理サービス。
/// 請求日前日のリマインド通知のスケジューリングとキャンセルを担当する。
///
/// ### enum をサービスとして使う理由
/// インスタンス化不要な static メソッドのみで構成されるため、
/// class/struct ではなく enum を使う（意図しないインスタンス生成を防止）。
/// パラメータはすべて Sendable（String, Date）なので、
/// Swift 6 の strict concurrency でも安全に使用できる。
enum NotificationService {

    // MARK: - 通知許可

    /// ユーザーに通知許可をリクエストする。
    /// async/await パターンで結果を返す（Completion handler は使わない）。
    /// - Returns: 許可された場合 true
    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            let authorized = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if authorized {
                registerNotificationCategories()
            }
            return authorized
        } catch {
            print("通知許可リクエストエラー: \(error)")
            return false
        }
    }

    /// 通知のカスタムカテゴリとアクション（「見直す」ボタンなど）を登録する。
    static func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()

        // アプリ起動（フォアグラウンド移行）を伴う見直しアクション
        let reviewAction = UNNotificationAction(
            identifier: "REVIEW_ACTION",
            title: "🔍 アプリで今すぐ見直す",
            options: [.foreground]
        )

        // トライアル終了警告用のカテゴリ
        let trialCategory = UNNotificationCategory(
            identifier: "TRIAL_REMINDER",
            actions: [reviewAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([trialCategory])
    }

    // MARK: - リマインド通知のスケジュール

    /// サブスクリプションの請求日前にリマインド通知をスケジュールする。
    ///
    /// - Parameters:
    ///   - subscriptionName: サブスク名（通知の本文に表示）
    ///   - nextPaymentDate: 次回請求日
    ///   - identifier: 通知の一意識別子（キャンセル時にも使用）
    ///   - leadDays: 通知を送る何日前か（nilの場合はUserDefaultsの設定またはデフォルト1を使用）
    static func scheduleReminder(
        subscriptionName: String,
        nextPaymentDate: Date,
        identifier: String,
        leadDays: Int? = nil
    ) async {
        // 設定で通知がOFFの場合はスキップ
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        // 引数がnilならUserDefaultsから取得（デフォルトは1日前）
        let days = leadDays ?? {
            let savedDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
            return savedDays > 0 ? savedDays : 1
        }()

        let calendar = Calendar.current

        // 請求日の指定した日数前を計算
        guard let reminderDate = calendar.date(
            byAdding: .day, value: -days, to: nextPaymentDate
        ) else { return }

        // 過去の日付にはスケジュールしない
        guard reminderDate > Date() else { return }

        // 通知コンテンツの作成
        let content = UNMutableNotificationContent()
        let dayText = days == 1 ? "明日" : "\(days)日前"
        content.title = "\(dayText)は請求日です"
        content.body = "\(subscriptionName) の請求があります"
        content.sound = .default

        // 指定日前の午前9時にトリガーする設定
        var triggerComponents = calendar.dateComponents(
            [.year, .month, .day], from: reminderDate
        )
        triggerComponents.hour = 9
        triggerComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("通知スケジュールエラー: \(error)")
        }
    }

    /// 無料体験終了前のリマインド通知をスケジュールする。
    /// 終了日の2日前と1日前の午前9時に通知を送る。
    /// - Parameters:
    ///   - subscriptionName: サブスク名
    ///   - trialEndDate: トライアル終了日
    ///   - identifier: 通知の基本となる一意識別子
    static func scheduleTrialReminder(
        subscriptionName: String,
        trialEndDate: Date,
        identifier: String
    ) async {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()

        // 2日前と1日前のスケジュール設定
        let offsets = [-2, -1]
        
        for offset in offsets {
            guard let reminderDate = calendar.date(byAdding: .day, value: offset, to: trialEndDate) else { continue }
            guard reminderDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            let dayText = offset == -1 ? "明日" : "明後日"
            content.title = "🚨 無料体験終了リマインダー"
            content.body = "「\(subscriptionName)」の無料体験期間が\(dayText)で終了します！自動的に課金が発生する可能性があります。解約忘れはありませんか？"
            content.sound = .default
            content.categoryIdentifier = "TRIAL_REMINDER" // リッチアクションカテゴリの適用
            
            // ディープリンク等で利用できるようにサブスク名をUserInfoに付与
            content.userInfo = ["subscriptionName": subscriptionName]

            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            triggerComponents.hour = 9
            triggerComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(identifier)_day\(offset)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                print("トライアル通知スケジュールエラー: \(error)")
            }
        }
    }

    /// サブスク終了前のリマインド通知をスケジュールする。
    /// 終了日の前日の午前9時に通知を送る。
    static func scheduleEndDateReminder(
        subscriptionName: String,
        endDate: Date,
        identifier: String
    ) async {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()

        // 1日前のスケジュール設定
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: endDate) else { return }
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "明日、サブスクの終了日です"
        content.body = "\(subscriptionName) の設定した終了日が明日になります。解約手続きはお済みですか？"
        content.sound = .default

        var triggerComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        triggerComponents.hour = 9
        triggerComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(identifier)_enddate",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("終了日通知スケジュールエラー: \(error)")
        }
    }

    /// 月1サブスク見直しリマインド通知をスケジュールする。
    /// 指定された日にち（1〜31日。その月の日数に自動クランプ）および時間に、今後12ヶ月分の個別通知をスケジュールします。
    /// - Parameters:
    ///   - day: 毎月通知を送る日にち（1〜31）
    ///   - hour: 通知を送る時間（時）
    ///   - minute: 通知を送る時間（分）
    static func scheduleMonthlyReviewReminder(day: Int, hour: Int, minute: Int) async {
        // 設定で通知がOFFの場合はキャンセルしてスキップ
        guard UserDefaults.standard.bool(forKey: "monthlyReviewNotificationEnabled") else {
            cancelMonthlyReviewReminder()
            return
        }

        let center = UNUserNotificationCenter.current()
        
        // 既存のすべての個別見直し通知を一度キャンセルして重複を防ぐ
        cancelMonthlyReviewReminder()

        let calendar = Calendar.current
        let today = Date()
        
        // 今後12ヶ月分の見直し通知をそれぞれ算出してスケジュール
        for i in 0..<12 {
            if let targetMonthDate = calendar.date(byAdding: .month, value: i, to: today) {
                var targetComp = calendar.dateComponents([.year, .month], from: targetMonthDate)
                let y = targetComp.year ?? 2026
                let m = targetComp.month ?? 1
                
                // その月の日数に合わせて日にちを自動クランプ（例: 2月31日 ➡ 2月28日/29日）
                var targetDay = day
                if let monthRange = calendar.range(of: .day, in: .month, for: targetMonthDate) {
                    let maxDays = monthRange.count
                    if targetDay > maxDays {
                        targetDay = maxDays
                    }
                }
                
                targetComp.day = targetDay
                targetComp.hour = hour
                targetComp.minute = minute
                
                if let finalDate = calendar.date(from: targetComp), finalDate > today {
                    let content = UNMutableNotificationContent()
                    content.title = "🔍 【月1コテサク見直しデー】無駄な出費を削減！"
                    content.body = "今月もサブスクの『見直し診断』を行う日になりました！使用していないアプリや、満足度の低いサービスはありませんか？アプリを開いて、固定費を即座に削減しましょう！💰✨"
                    content.sound = .default
                    content.userInfo = ["type": "monthly_review"]
                    
                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                    
                    let request = UNNotificationRequest(
                        identifier: "monthly_review_reminder_\(i)",
                        content: content,
                        trigger: trigger
                    )
                    
                    do {
                        try await center.add(request)
                    } catch {
                        print("月1見直し個別通知スケジュールエラー (月\(i)): \(error)")
                    }
                }
            }
        }
    }

    /// 月1サブスク見直しリマインド通知をキャンセルする。
    static func cancelMonthlyReviewReminder() {
        let identifiers = (0..<12).map { "monthly_review_reminder_\($0)" }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - 通知のキャンセル

    /// 指定した識別子の通知をキャンセルする。
    /// - Parameter identifier: キャンセルする通知の識別子
    static func cancelReminder(identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// 全てのリマインド通知をキャンセルする。
    static func cancelAllReminders() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    // MARK: - ヘルパー

    /// サブスク名と開始日から一意な通知識別子を生成する。
    /// 同じサブスクに対して常に同じIDが返るため、再スケジュールやキャンセルが可能。
    /// - Parameters:
    ///   - name: サブスク名
    ///   - startDate: サブスク開始日
    /// - Returns: 通知識別子の文字列
    static func makeIdentifier(name: String, startDate: Date) -> String {
        let timestamp = Int(startDate.timeIntervalSince1970)
        return "reminder_\(name)_\(timestamp)"
    }
}

// MARK: - ReviewRequestService

import StoreKit
import UIKit

/// ASO対策としての「App Store レビュー促進機能」を管理するサービス
/// ユーザーが最も満足し、アプリの価値を実感している瞬間（Aha! Moment）にレビューを促します。
class ReviewRequestService {
    static let shared = ReviewRequestService()

    /// UserDefaults を直接用いてデータを永続化（SwiftUI依存を排除）
    private var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: "reviewRequestLaunchCount") }
        set { UserDefaults.standard.set(newValue, forKey: "reviewRequestLaunchCount") }
    }

    private var lastVersionPromptedForReview: String {
        get { UserDefaults.standard.string(forKey: "lastVersionPromptedForReview") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastVersionPromptedForReview") }
    }

    private init() {}

    /// アプリ起動回数をインクリメントします
    func incrementLaunchCount() {
        launchCount += 1
        print("[ReviewRequestService] Launch count incremented: \(launchCount)")
    }

    /// アプリ起動時の条件判定に基づき、レビューを要求します
    /// - 条件: 起動回数が3回以上 ＆ 登録サブスクが1件以上
    @MainActor
    func requestReviewIfLaunchConditionsMet(activeSubscriptionCount: Int) {
        guard launchCount >= 3 else {
            print("[ReviewRequestService] Launch check - Review skipped: Launch count is \(launchCount) (requires >= 3)")
            return
        }
        guard activeSubscriptionCount >= 1 else {
            print("[ReviewRequestService] Launch check - Review skipped: Registered subscription count is \(activeSubscriptionCount) (requires >= 1)")
            return
        }
        print("[ReviewRequestService] Launch conditions met! Proceeding to prompt review...")
        requestReview()
    }

    /// 新規サブスクリプションの登録が成功した瞬間にレビューを要求します（Aha! Moment 1）
    @MainActor
    func requestReviewIfSubscriptionAdded() {
        print("[ReviewRequestService] Add subscription trigger - Proceeding to prompt review...")
        requestReview()
    }

    /// 無駄なサブスクの削減・解約に成功した瞬間にレビューを要求します（Aha! Moment 2）
    @MainActor
    func requestReviewIfSavingsAchieved() {
        print("[ReviewRequestService] Savings achieved trigger - Proceeding to prompt review...")
        requestReview()
    }

    /// コアとなるStoreKitレビュー要求ロジック
    @MainActor
    private func requestReview() {
        // 現在のアプリバージョン（例: "1.0.1"）を取得
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            print("[ReviewRequestService] Error: Could not retrieve CFBundleShortVersionString")
            return
        }

        // 同一バージョンでの重複表示防止（ユーザー体験の保護）
        if currentVersion == lastVersionPromptedForReview {
            print("[ReviewRequestService] Review skipped: Already prompted for version \(currentVersion) to prevent spamming")
            return
        }

        // アクティブなUIWindowSceneを取得して要求を実行
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
            lastVersionPromptedForReview = currentVersion
            print("[ReviewRequestService] StoreKit requestReview executed successfully for version \(currentVersion)!")
        } else {
            print("[ReviewRequestService] Error: Active UIWindowScene could not be retrieved")
        }
    }
}
