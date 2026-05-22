//
//  AppDelegate.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/22.
//

import UIKit
import UserNotifications

/// アプリのデリゲート。通知アクションのハンドリングなどを担当する。
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 通知センターのデリゲートを自分自身に設定
        UNUserNotificationCenter.current().delegate = self
        
        // アプリ起動時に通知カテゴリとアクションを登録
        NotificationService.registerNotificationCategories()
        
        return true
    }

    // ユーザーが通知内のアクションをタップした際に呼ばれるデリゲートメソッド
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        if actionIdentifier == "REVIEW_ACTION" {
            // 見直しアクション（または通知自体のタップ）の際にNotificationCenterでブロードキャスト
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowReviewWizard"),
                    object: nil,
                    userInfo: userInfo
                )
            }
        } else if actionIdentifier == UNNotificationDefaultActionIdentifier {
            // アクションボタンではなく、通知バナー本体をタップして起動した場合も同様に遷移をトリガー
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowReviewWizard"),
                    object: nil,
                    userInfo: userInfo
                )
            }
        }

        completionHandler()
    }

    // アプリがフォアグラウンドにいる時に通知が届いた場合のハンドリング
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでもバナー、音声、バッジを表示する
        completionHandler([.banner, .list, .sound, .badge])
    }
}
