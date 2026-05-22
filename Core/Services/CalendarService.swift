//
//  CalendarService.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/22.
//

import EventKit
import Foundation

/// iOSのカレンダー（EventKit）と連携するサービス。
/// サブスクの次回請求日や無料トライアル終了日のカレンダー登録・更新・削除を管理する。
enum CalendarService {

    /// カレンダーの共有イベントストアインスタンス
    private static let eventStore = EKEventStore()

    /// カレンダーの書き込み権限があるかどうかを判定する
    static var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            return status == .writeOnly || status == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    /// カレンダー連携の権限リクエストを実行する
    /// - Returns: 許可された場合 true
    static func requestAuthorization() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                // iOS 17 以降の書き込み専用権限をリクエスト
                return try await eventStore.requestWriteOnlyAccessToEvents()
            } else {
                return try await eventStore.requestAccess(to: .event)
            }
        } catch {
            print("カレンダー権限リクエストエラー: \(error)")
            return false
        }
    }

    /// サブスク情報をカレンダーイベントに同期（新規登録、または既存の更新）する
    /// - Parameter subscription: 同期対象のサブスクリプション
    static func syncSubscription(_ subscription: Subscription) async {
        // 設定でカレンダー自動連携がOFFの場合はスキップ
        guard UserDefaults.standard.bool(forKey: "calendarSyncEnabled") else { return }
        guard isAuthorized else { return }

        let store = eventStore

        // 1. 通常請求日イベントの同期
        if subscription.isActive {
            let amountText = CurrencyHelper.formatted(amount: subscription.ownShareAmount)
            let eventTitle = "🔔 コテサク: \(subscription.name) 請求日 (\(amountText))"
            let eventDate = subscription.nextPaymentDate

            do {
                if let eventId = subscription.calendarEventIdentifier, let existingEvent = store.event(withIdentifier: eventId) {
                    // 既存イベントの更新
                    existingEvent.title = eventTitle
                    existingEvent.startDate = Calendar.current.startOfDay(for: eventDate)
                    existingEvent.endDate = Calendar.current.startOfDay(for: eventDate).addingTimeInterval(86400 - 1)
                    existingEvent.notes = makeNotes(for: subscription, isTrial: false)
                    existingEvent.url = URL(string: "kotesaku://")
                    try store.save(existingEvent, span: .thisEvent, commit: true)
                } else {
                    // 新規イベントの作成
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.calendar = store.defaultCalendarForNewEvents
                    newEvent.title = eventTitle
                    newEvent.isAllDay = true
                    newEvent.startDate = Calendar.current.startOfDay(for: eventDate)
                    newEvent.endDate = Calendar.current.startOfDay(for: eventDate).addingTimeInterval(86400 - 1)
                    newEvent.notes = makeNotes(for: subscription, isTrial: false)
                    newEvent.url = URL(string: "kotesaku://")

                    try store.save(newEvent, span: .thisEvent, commit: true)
                    subscription.calendarEventIdentifier = newEvent.eventIdentifier
                }
            } catch {
                print("通常請求日カレンダー同期エラー: \(error)")
            }
        } else {
            // 非アクティブなサブスクは通常請求日イベントを削除
            await removeNormalPaymentEvent(for: subscription)
        }

        // 2. 無料トライアル終了日イベントの同期
        // トライアル中で、かつ無料体験終了日が設定されている場合
        if subscription.isActive, let trialEndDate = subscription.trialEndDate, subscription.isTrial {
            let eventTitle = "🚨 コテサク警告: \(subscription.name) 無料トライアル終了"

            do {
                if let trialEventId = subscription.trialCalendarEventIdentifier, let existingEvent = store.event(withIdentifier: trialEventId) {
                    // 既存トライアルイベントの更新
                    existingEvent.title = eventTitle
                    existingEvent.startDate = Calendar.current.startOfDay(for: trialEndDate)
                    existingEvent.endDate = Calendar.current.startOfDay(for: trialEndDate).addingTimeInterval(86400 - 1)
                    existingEvent.notes = makeNotes(for: subscription, isTrial: true)
                    existingEvent.url = URL(string: "kotesaku://")
                    try store.save(existingEvent, span: .thisEvent, commit: true)
                } else {
                    // 新規トライアルイベントの作成
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.calendar = store.defaultCalendarForNewEvents
                    newEvent.title = eventTitle
                    newEvent.isAllDay = true
                    newEvent.startDate = Calendar.current.startOfDay(for: trialEndDate)
                    newEvent.endDate = Calendar.current.startOfDay(for: trialEndDate).addingTimeInterval(86400 - 1)
                    newEvent.notes = makeNotes(for: subscription, isTrial: true)
                    newEvent.url = URL(string: "kotesaku://")

                    try store.save(newEvent, span: .thisEvent, commit: true)
                    subscription.trialCalendarEventIdentifier = newEvent.eventIdentifier
                }
            } catch {
                print("無料トライアルカレンダー同期エラー: \(error)")
            }
        } else {
            // トライアルを過ぎた、またはトライアルなしの場合はカレンダーから削除
            await removeTrialPaymentEvent(for: subscription)
        }
    }

    /// サブスクリプションに関連するすべてのカレンダーイベントを削除する
    /// - Parameter subscription: 対象のサブスクリプション
    static func removeEvents(for subscription: Subscription) async {
        guard isAuthorized else { return }
        await removeNormalPaymentEvent(for: subscription)
        await removeTrialPaymentEvent(for: subscription)
    }

    /// 通常請求日のイベントを削除する
    private static func removeNormalPaymentEvent(for subscription: Subscription) async {
        guard let id = subscription.calendarEventIdentifier else { return }
        do {
            if let event = eventStore.event(withIdentifier: id) {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            }
            subscription.calendarEventIdentifier = nil
        } catch {
            print("通常請求日カレンダーイベント削除エラー: \(error)")
        }
    }

    /// 無料トライアル終了日のイベントを削除する
    private static func removeTrialPaymentEvent(for subscription: Subscription) async {
        guard let id = subscription.trialCalendarEventIdentifier else { return }
        do {
            if let event = eventStore.event(withIdentifier: id) {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            }
            subscription.trialCalendarEventIdentifier = nil
        } catch {
            print("無料トライアルカレンダーイベント削除エラー: \(error)")
        }
    }

    /// 既存のすべてのサブスクリプションを一括カレンダー同期する
    /// - Parameter subscriptions: サブスクリプション一覧
    static func syncAllSubscriptions(subscriptions: [Subscription]) async {
        for subscription in subscriptions {
            await syncSubscription(subscription)
        }
    }

    /// 既存のすべてのサブスクリプションのカレンダー同期を解除し、カレンダー上から削除する
    /// - Parameter subscriptions: サブスクリプション一覧
    static func removeAllEvents(for subscriptions: [Subscription]) async {
        for subscription in subscriptions {
            await removeEvents(for: subscription)
        }
    }

    // MARK: - ヘルパー

    /// カレンダーイベント用のメモテキストを作成する
    private static func makeNotes(for subscription: Subscription, isTrial: Bool) -> String {
        var notesText = ""
        if isTrial {
            notesText += "⚠️ 無料トライアル（体験期間）の最終日です。本日までに解約手続きを行わない場合、自動的に有料プランに移行し、月額等の課金が発生する可能性があります。\n解約を希望される場合は、速やかに手続きを行ってください。\n\n"
        } else {
            notesText += "コテサク（SubsqManager）で管理している固定費サブスクの請求日です。\n\n"
        }

        notesText += "【サブスクリプション詳細】\n"
        notesText += "・サブスク名: \(subscription.name)\n"
        notesText += "・カテゴリ: \(subscription.category.localizedName)\n"
        
        let amountFormatted = CurrencyHelper.formatted(amount: subscription.amount)
        notesText += "・契約料金: \(amountFormatted) / \(subscription.billingCycle.localizedName)\n"

        if subscription.isShared {
            notesText += "・割り勘設定: ON\n"
            notesText += "  - 共有人数: \(subscription.splitCount) 人\n"
            notesText += "  - 自己負担率: \(Int(subscription.ownSharePercentage * 100)) %\n"
            
            let ownShareAmountFormatted = CurrencyHelper.formatted(amount: subscription.ownShareAmount)
            notesText += "  - 実質自己負担額: \(ownShareAmountFormatted) / \(subscription.billingCycle.localizedName)\n"
        }

        if !subscription.notes.isEmpty {
            notesText += "・メモ: \(subscription.notes)\n"
        }

        notesText += "\n--------------------\n"
        notesText += "➔ コテサクアプリで今すぐ見直す: kotesaku://"
        
        return notesText
    }
}
