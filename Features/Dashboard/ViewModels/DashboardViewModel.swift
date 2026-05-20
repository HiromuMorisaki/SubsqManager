//
//  DashboardViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// ダッシュボード画面のViewModel。
/// サブスクリプション一覧から月額合計・年額合計・次回請求情報を計算する。
///
/// ### 計算の仕組み
/// 各 Subscription は billingCycle（週額/月額/年額）を持っており、
/// BillingCycle.monthlyMultiplier / yearlyMultiplier を使って統一単位に換算する。
/// 例: 週額¥500 → 月額換算 ¥500 × (52/12) ≈ ¥2,167
@Observable
final class DashboardViewModel {

    /// 月額合計を計算する。
    /// 全アクティブサブスクの金額を monthlyMultiplier で月額に変換して合算。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 月額合計金額（Decimal）
    func totalMonthlyAmount(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions.reduce(Decimal.zero) { total, subscription in
            total + subscription.monthlyAmount
        }
    }

    /// 年額合計を計算する。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 年額合計金額（Decimal）
    func totalYearlyAmount(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions.reduce(Decimal.zero) { total, subscription in
            total + subscription.yearlyAmount
        }
    }

    /// 次回請求が最も近いサブスクリプションを返す。
    /// nextPaymentDate が現在以降のもののうち、最も早い日付のものを選ぶ。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 次回請求が最も近いサブスク（なければnil）
    func nextUpcomingSubscription(_ subscriptions: [Subscription]) -> Subscription? {
        let now = Date()
        return subscriptions
            .filter { $0.nextPaymentDate >= now }
            .min { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    /// 直近の請求予定リスト（最大5件）を返す。
    /// - Parameter subscriptions: @Queryで取得されたアクティブサブスクリプション
    /// - Returns: 次回請求日が近い順にソートされた配列（最大5件）
    func upcomingSubscriptions(_ subscriptions: [Subscription]) -> [Subscription] {
        let now = Date()
        return subscriptions
            .filter { $0.nextPaymentDate >= now }
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
            .prefix(5)
            .map { $0 }
    }
}
