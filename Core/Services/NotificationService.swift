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
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("通知許可リクエストエラー: \(error)")
            return false
        }
    }

    // MARK: - リマインド通知のスケジュール

    /// サブスクリプションの請求日前日にリマインド通知をスケジュールする。
    ///
    /// - Parameters:
    ///   - subscriptionName: サブスク名（通知の本文に表示）
    ///   - nextPaymentDate: 次回請求日
    ///   - identifier: 通知の一意識別子（キャンセル時にも使用）
    static func scheduleReminder(
        subscriptionName: String,
        nextPaymentDate: Date,
        identifier: String
    ) async {
        // 設定で通知がOFFの場合はスキップ
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        let calendar = Calendar.current

        // 請求日の前日を計算
        guard let reminderDate = calendar.date(
            byAdding: .day, value: -1, to: nextPaymentDate
        ) else { return }

        // 過去の日付にはスケジュールしない
        guard reminderDate > Date() else { return }

        // 通知コンテンツの作成
        let content = UNMutableNotificationContent()
        content.title = "明日は請求日です"
        content.body = "\(subscriptionName) の請求があります"
        content.sound = .default

        // 前日の午前9時にトリガーする設定
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
            content.title = "無料体験が\(dayText)終了します"
            content.body = "\(subscriptionName) の無料体験期間が終了し、課金が開始される可能性があります。"
            content.sound = .default

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
