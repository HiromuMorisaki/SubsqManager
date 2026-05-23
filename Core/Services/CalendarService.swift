//
//  CalendarService.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/22.
//

import EventKit
import Foundation
import SwiftData

/// 外部カレンダーから検出されたサブスクリプションのインポート用候補
struct SubscriptionCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: Decimal
    var category: Category
    var paymentDate: Date
    var notes: String
}

/// iOSのカレンダー（EventKit）と連携するサービス。
/// サブスクの次回請求日や無料トライアル終了日のカレンダー登録・更新・削除を管理する。
@MainActor
enum CalendarService {

    /// カレンダーの共有イベントストアインスタンス
    private static let eventStore = EKEventStore()

    /// カレンダーの書き込み権限があるかどうかを判定する
    static var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            return status == .fullAccess // 既存予定の検索と削除をするためにフルアクセス権限が必要
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    /// 書き込み可能なカレンダー一覧を取得する
    static func getWritableCalendars() -> [EKCalendar] {
        guard isAuthorized else { return [] }
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }

    /// カレンダー連携の権限リクエストを実行する
    /// - Returns: 許可された場合 true
    static func requestAuthorization() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                // iOS 17 以降は重複防止（既存の予定を読み取って削除する）のためにフルアクセス権限をリクエスト
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return try await eventStore.requestAccess(to: .event)
            }
        } catch {
            print("カレンダー権限リクエストエラー: \(error)")
            return false
        }
    }

    /// サブスク情報をカレンダーイベントに同期（新規登録）する。
    /// 【自己修復型の重複回避】：同期前に同じ日付・同じ件名カテゴリの既存コテサクイベントをすべて完全にクリーンアップした上で新規保存します。
    /// - Parameter subscription: 同期対象のサブスクリプション
    static func syncSubscription(_ subscription: Subscription) async {
        // 設定でカレンダー自動連携がOFFの場合はスキップ
        guard UserDefaults.standard.bool(forKey: "calendarSyncEnabled") else { return }
        guard isAuthorized else { return }

        let store = eventStore

        // 過去3ヶ月〜未来12ヶ月の範囲から同じサブスク名のイベントを一掃（自己修復・重複防止）
        cleanAllEventsGlobally(for: subscription.name, store: store)

        // 1. 通常請求日イベントの同期
        if subscription.isActive {
            let amountText = CurrencyHelper.formatted(amount: subscription.ownShareAmount)
            let eventTitle = "🔔 コテサク: \(subscription.name) 請求日 (\(amountText))"
            let eventDate = subscription.nextPaymentDate

            // カレンダー上の既存の重複イベント（「コテサク」「請求日」とサブスク名を含むもの）を事前に削除する
            removeDuplicateEvents(titleKeyword: "請求日", subName: subscription.name, on: eventDate, store: store)

            do {
                // 新規イベントの作成
                let newEvent = EKEvent(eventStore: store)
                guard let targetCalendar = getDestinationCalendar(in: store) else {
                    print("通常請求日カレンダー同期エラー: 書き込み可能なカレンダーが見つかりません。")
                    return
                }
                newEvent.calendar = targetCalendar
                newEvent.title = eventTitle
                newEvent.isAllDay = true
                
                // 開始日を本来のサブスク開始日にして繰り返しを表現する
                // ただし、無料トライアル中の場合は無料トライアル終了日から請求予定を開始する
                let eventStartDate = (subscription.isTrial && subscription.trialEndDate != nil) ? subscription.trialEndDate! : subscription.startDate
                newEvent.startDate = Calendar.current.startOfDay(for: eventStartDate)
                newEvent.endDate = Calendar.current.startOfDay(for: eventStartDate).addingTimeInterval(86400 - 1)
                newEvent.notes = makeNotes(for: subscription, isTrial: false)
                newEvent.url = URL(string: "kotesaku://")
                // サイクルに応じた繰り返し設定を追加（プレミアム自動同期機能）
                if subscription.billingCycle != .oneTime {
                    let frequency: EKRecurrenceFrequency
                    switch subscription.billingCycle {
                    case .weekly:
                        frequency = .weekly
                    case .monthly:
                        frequency = .monthly
                    case .yearly:
                        frequency = .yearly
                    case .oneTime:
                        frequency = .monthly // ダミー値（到達不能）
                    }
                    
                    let rule = EKRecurrenceRule(
                        recurrenceWith: frequency,
                        interval: 1,
                        end: nil // 期限なしで自動的に繰り返す
                    )
                    newEvent.addRecurrenceRule(rule)
                }

                let span: EKSpan = (subscription.billingCycle == .oneTime) ? .thisEvent : .futureEvents
                try store.save(newEvent, span: span, commit: true)
                subscription.calendarEventIdentifier = newEvent.eventIdentifier
                try? subscription.modelContext?.save() // SwiftDataコンテキストの即時保存
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

            // カレンダー上の既存の重複トライアルイベントを事前に削除する
            removeDuplicateEvents(titleKeyword: "無料トライアル", subName: subscription.name, on: trialEndDate, store: store)

            do {
                // 新規トライアルイベントの作成
                let newEvent = EKEvent(eventStore: store)
                guard let targetCalendar = getDestinationCalendar(in: store) else {
                    print("無料トライアルカレンダー同期エラー: 書き込み可能なカレンダーが見つかりません。")
                    return
                }
                newEvent.calendar = targetCalendar
                newEvent.title = eventTitle
                newEvent.isAllDay = true
                newEvent.startDate = Calendar.current.startOfDay(for: trialEndDate)
                newEvent.endDate = Calendar.current.startOfDay(for: trialEndDate).addingTimeInterval(86400 - 1)
                newEvent.notes = makeNotes(for: subscription, isTrial: true)
                newEvent.url = URL(string: "kotesaku://")

                try store.save(newEvent, span: .thisEvent, commit: true)
                subscription.trialCalendarEventIdentifier = newEvent.eventIdentifier
                try? subscription.modelContext?.save() // SwiftDataコンテキストの即時保存
            } catch {
                print("無料トライアルカレンダー同期エラー: \(error)")
            }
        } else {
            // トライアルを過ぎた、またはトライアルなしの場合はカレンダーから削除
            await removeTrialPaymentEvent(for: subscription)
        }
    }
    
    /// 保存先のカレンダーを特定する共通ヘルパー
    private static func getDestinationCalendar(in store: EKEventStore) -> EKCalendar? {
        if let selectedId = UserDefaults.standard.string(forKey: "selectedCalendarIdentifier"),
           !selectedId.isEmpty,
           let selectedCalendar = store.calendar(withIdentifier: selectedId) {
            return selectedCalendar
        } else if let defaultCalendar = store.defaultCalendarForNewEvents {
            return defaultCalendar
        } else {
            return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
        }
    }

    /// カレンダー上の重複するコテサクイベントを根こそぎ削除する（自己修復・重複防止用）
    private static func removeDuplicateEvents(
        titleKeyword: String,
        subName: String,
        on date: Date,
        store: EKEventStore
    ) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = startDate.addingTimeInterval(86400) // 24時間枠
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let existingEvents = store.events(matching: predicate)
        
        var deletedIdentifiers = Set<String>()
        var deletedAny = false
        for event in existingEvents {
            let title = event.title ?? ""
            // コテサク、サブスク名、およびキーワード（請求日 or 無料トライアル）がすべてタイトルに一致する場合削除
            if title.contains("コテサク") && title.contains(subName) && title.contains(titleKeyword) {
                let identifier = event.eventIdentifier ?? ""
                if !identifier.isEmpty {
                    if deletedIdentifiers.contains(identifier) {
                        continue // すでに削除処理を指示済みのシリーズは重複して呼ばない
                    }
                    deletedIdentifiers.insert(identifier)
                }
                
                do {
                    try store.remove(event, span: .futureEvents, commit: false)
                    deletedAny = true
                } catch {
                    print("重複する予定「\(title)」の自動クリーンアップ失敗: \(error)")
                }
            }
        }
        
        if deletedAny {
            do {
                try store.commit()
            } catch {
                print("重複クリーンアップのコミット失敗: \(error)")
            }
        }
    }

    /// サブスクリプションに関連するすべてのカレンダーイベントを削除する
    /// - Parameter subscription: 対象のサブスクリプション
    static func removeEvents(for subscription: Subscription) async {
        guard isAuthorized else { return }
        await removeNormalPaymentEvent(for: subscription)
        await removeTrialPaymentEvent(for: subscription)
    }

    /// カレンダーイベントを識別子およびサブスク名から安全に削除する（削除済みオブジェクトのクラッシュ回避用）
    static func removeEvents(
        name: String,
        eventIdentifier: String?,
        trialEventIdentifier: String?
    ) async {
        guard isAuthorized else { return }
        
        let store = eventStore
        
        // 1. 通常請求日イベントの削除
        if let id = eventIdentifier, !id.isEmpty,
           let event = store.event(withIdentifier: id) {
            do {
                try store.remove(event, span: .futureEvents, commit: true)
            } catch {
                print("通常請求日カレンダーイベント削除エラー: \(error)")
            }
        }
        
        // 2. 無料トライアルイベントの削除
        if let id = trialEventIdentifier, !id.isEmpty,
           let event = store.event(withIdentifier: id) {
            do {
                try store.remove(event, span: .thisEvent, commit: true)
            } catch {
                print("無料トライアルカレンダーイベント削除エラー: \(error)")
            }
        }
        
        // 3. 自己修復：グローバル徹底クリーンアップ
        cleanAllEventsGlobally(for: name, store: store)
    }

    /// 通常請求日のイベントを削除する
    private static func removeNormalPaymentEvent(for subscription: Subscription) async {
        if let id = subscription.calendarEventIdentifier,
           let event = eventStore.event(withIdentifier: id) {
            do {
                try eventStore.remove(event, span: .futureEvents, commit: true)
            } catch {
                print("通常請求日カレンダーイベント削除エラー: \(error)")
            }
        }
        
        // 自己修復：識別子での削除失敗や古い重複がある場合の徹底クリーンアップ
        cleanAllEventsGlobally(for: subscription.name, store: eventStore)
        subscription.calendarEventIdentifier = nil
        try? subscription.modelContext?.save() // SwiftDataコンテキストの即時保存
    }

    /// 無料トライアル終了日のイベントを削除する
    private static func removeTrialPaymentEvent(for subscription: Subscription) async {
        if let id = subscription.trialCalendarEventIdentifier,
           let event = eventStore.event(withIdentifier: id) {
            do {
                try eventStore.remove(event, span: .thisEvent, commit: true)
            } catch {
                print("無料トライアルカレンダーイベント削除エラー: \(error)")
            }
        }
        
        // 自己修復：識別子での削除失敗や古い重複がある場合の徹底クリーンアップ
        cleanAllEventsGlobally(for: subscription.name, store: eventStore)
        subscription.trialCalendarEventIdentifier = nil
        try? subscription.modelContext?.save() // SwiftDataコンテキストの即時保存
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

    /// 指定されたサブスク名の「コテサク」予定を、過去3ヶ月〜未来12ヶ月の範囲から完全に一掃する（自己修復・徹底クリーンアップ用）
    static func cleanAllEventsGlobally(for subName: String, store: EKEventStore) {
        let calendar = Calendar.current
        let today = Date()
        
        // 過去3ヶ月〜未来12ヶ月の範囲
        guard let startDate = calendar.date(byAdding: .month, value: -3, to: today),
              let endDate = calendar.date(byAdding: .month, value: 12, to: today) else {
            return
        }
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let existingEvents = store.events(matching: predicate)
        
        var deletedIdentifiers = Set<String>()
        var deletedAny = false
        for event in existingEvents {
            let title = event.title ?? ""
            if title.contains("コテサク") && title.contains(subName) {
                let identifier = event.eventIdentifier ?? ""
                if !identifier.isEmpty {
                    if deletedIdentifiers.contains(identifier) {
                        continue // すでに同一シリーズの削除指示を出している場合はスキップ（EventKitの二重削除破損対策）
                    }
                    deletedIdentifiers.insert(identifier)
                }
                
                do {
                    try store.remove(event, span: .futureEvents, commit: false)
                    deletedAny = true
                } catch {
                    print("グローバルクリーンアップでの削除失敗「\(title)」: \(error)")
                }
            }
        }
        
        if deletedAny {
            do {
                try store.commit()
            } catch {
                print("グローバルクリーンアップのコミット失敗: \(error)")
            }
        }
    }

    // MARK: - 外部カレンダー連携インポートロジック

    /// 指定された年月の外部カレンダーイベント（Googleカレンダー、TimeTree、Outlook等）をスキャンし、サブスクリプション候補を自動検出する
    static func detectSubscriptionCandidates(for yearMonth: Date) async -> [SubscriptionCandidate] {
        // カレンダー権限がない場合は空
        guard isAuthorized else { return [] }
        
        let store = eventStore
        let calendar = Calendar.current
        
        // 指定年月の開始日と終了日を算出
        guard let monthRange = calendar.range(of: .day, in: .month, for: yearMonth),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: yearMonth)) else {
            return []
        }
        
        let endOfMonth = calendar.date(byAdding: .day, value: monthRange.count, to: startOfMonth) ?? yearMonth
        
        let predicate = store.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let events = store.events(matching: predicate)
        
        var candidates: [SubscriptionCandidate] = []
        
        // サブスク候補判定用のキーワード（ケースインセンシティブ）
        let keywords = [
            "netflix", "spotify", "hulu", "amazon", "prime", "youtube", "apple", "google",
            "microsoft", "office", "adobe", "github", "icloud", "dropbox", "manga", "mora",
            "nhk", "u-next", "dアニメ", "dazn", "disney", "fanbox", "fantia", "pixiv",
            "premium", "プレミアム", "サブスク", "月会費", "年会費", "定期便", "支払",
            "引き落とし", "引落", "課金", "会費", "ドメイン", "サーバー", "timetree"
        ]
        
        for event in events {
            let title = event.title ?? ""
            let lowerTitle = title.lowercased()
            
            // コテサク自身の登録イベントは候補から除外
            if title.contains("コテサク") {
                continue
            }
            
            // キーワードマッチング
            let matchesKeyword = keywords.contains { lowerTitle.contains($0) }
            
            if matchesKeyword {
                // 金額の抽出（正規表現）
                let amount = extractAmount(from: title) ?? 1000 // 未検出時のデフォルト
                
                // カテゴリの自動判定
                let category = autoDetectCategory(title: lowerTitle)
                
                // 支払予定日
                let paymentDate = event.startDate ?? Date()
                
                let candidate = SubscriptionCandidate(
                    name: cleanTitle(title),
                    amount: amount,
                    category: category,
                    paymentDate: paymentDate,
                    notes: "カレンダー「\(event.calendar?.title ?? "外部連携")」からインポート"
                )
                candidates.append(candidate)
            }
        }
        
        // 同一名称・同一日の重複候補を単一にユニーク化
        var uniqueCandidates: [SubscriptionCandidate] = []
        for candidate in candidates {
            if !uniqueCandidates.contains(where: { $0.name == candidate.name && calendar.isDate($0.paymentDate, inSameDayAs: candidate.paymentDate) }) {
                uniqueCandidates.append(candidate)
            }
        }
        
        return uniqueCandidates.sorted { $0.paymentDate < $1.paymentDate }
    }

    /// イベントタイトルから金額（数値）を自動抽出する正規表現ロジック
    private static func extractAmount(from title: String) -> Decimal? {
        let cleaned = title.replacingOccurrences(of: ",", with: "")
        
        let patterns = [
            "¥\\s*(\\d+)",
            "(\\d+)\\s*円",
            "\\$\\s*(\\d+(\\.\\d+)?)",
            "(\\d+)\\s*yen"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)) {
                
                if match.numberOfRanges >= 2 {
                    let range = match.range(at: 1)
                    if let swiftRange = Range(range, in: cleaned) {
                        let numStr = cleaned[swiftRange]
                        if let val = Double(numStr) {
                            return Decimal(val)
                        }
                    }
                }
            }
        }
        
        // 3桁以上の数字を見つけるフォールバック
        if let regex = try? NSRegularExpression(pattern: "\\b(\\d{3,})\\b", options: []),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)) {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: cleaned) {
                let numStr = cleaned[swiftRange]
                if let val = Double(numStr) {
                    return Decimal(val)
                }
            }
        }
        
        return nil
    }

    /// イベント名からカテゴリを自動判別
    private static func autoDetectCategory(title: String) -> Category {
        let t = title.lowercased()
        if t.contains("netflix") || t.contains("hulu") || t.contains("youtube") || t.contains("prime video") || t.contains("disney") || t.contains("u-next") || t.contains("tv") || t.contains("abema") {
            return .entertainment
        }
        if t.contains("spotify") || t.contains("music") || t.contains("apple music") || t.contains("mora") || t.contains("line music") {
            return .music
        }
        if t.contains("manga") || t.contains("book") || t.contains("電子書籍") || t.contains("コミック") || t.contains("kindle") || t.contains("マガジン") {
            return .manga
        }
        if t.contains("sports") || t.contains("dazn") || t.contains("ジム") || t.contains("フィットネス") || t.contains("choco") {
            return .sports
        }
        if t.contains("game") || t.contains("nintendo") || t.contains("playstation") || t.contains("xbox") || t.contains("steam") || t.contains("ソシャゲ") {
            return .game
        }
        if t.contains("kids") || t.contains("子育て") || t.contains("育児") || t.contains("おもちゃ") {
            return .kids
        }
        if t.contains("fan") || t.contains("ファンクラブ") || t.contains("fc") || t.contains("サロン") {
            return .fanclub
        }
        if t.contains("adobe") || t.contains("microsoft") || t.contains("office") || t.contains("github") || t.contains("copilot") || t.contains("chatgpt") || t.contains("slack") || t.contains("zoom") || t.contains("notion") {
            return .work
        }
        if t.contains("chatgpt") || t.contains("copilot") || t.contains("gemini") || t.contains("openai") || t.contains("claude") || t.contains("midjourney") {
            return .ai
        }
        if t.contains("icloud") || t.contains("dropbox") || t.contains("google one") || t.contains("cloud") || t.contains("drive") || t.contains("aws") {
            return .cloud
        }
        if t.contains("healthcare") || t.contains("heart") || t.contains("ヘルスケア") || t.contains("健康") || t.contains("サプリ") {
            return .healthcare
        }
        if t.contains("food") || t.contains("宅配") || t.contains("弁当") || t.contains("クックパッド") || t.contains("オイシックス") || t.contains("スタバ") {
            return .food
        }
        if t.contains("finance") || t.contains("マネー") || t.contains("家計簿") || t.contains("株") || t.contains("ゴールドカード") || t.contains("年会費") {
            return .financial
        }
        return .other
    }

    /// イベント名から不要なノイズを除去して綺麗にする
    private static func cleanTitle(_ title: String) -> String {
        var t = title
        let noise = ["の支払い", "支払い", "支払", "の引落", "引き落とし", "引落", "課金", "定期便", "登録", "決済", "の引き落とし", "の支払"]
        for word in noise {
            t = t.replacingOccurrences(of: word, with: "")
        }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("¥") || t.hasPrefix("$") {
            t = String(t.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t.isEmpty ? title : t
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
        notesText += "・カテゴリ: \(subscription.category.displayName)\n"
        
        let amountFormatted = CurrencyHelper.formatted(amount: subscription.amount)
        notesText += "・契約料金: \(amountFormatted) / \(subscription.billingCycle.displayName)\n"

        if subscription.isShared {
            notesText += "・割り勘設定: ON\n"
            notesText += "  - 共有人数: \(subscription.splitCount) 人\n"
            notesText += "  - 自己負担率: \(Int(subscription.ownSharePercentage * 100)) %\n"
            
            let ownShareAmountFormatted = CurrencyHelper.formatted(amount: subscription.ownShareAmount)
            notesText += "  - 実質自己負担額: \(ownShareAmountFormatted) / \(subscription.billingCycle.displayName)\n"
        }

        if !subscription.notes.isEmpty {
            notesText += "・メモ: \(subscription.notes)\n"
        }

        notesText += "\n--------------------\n"
        notesText += "➔ コテサクアプリで今すぐ見直す: kotesaku://"
        
        return notesText
    }
}

/// データベース内の重複するサブスクリプションを検出・クリーンアップするサービス。
enum SubscriptionDeduplicator {
    
    /// アクティブなサブスクリプションの重複を自動的に検出して統合（デデュープ）する。
    /// 同名（スペース無視、大文字小文字無視）のアイテムが複数存在する場合、
    /// 最新のものを1つだけ残し、他を削除します。
    @MainActor
    static func deduplicateActiveSubscriptions(using modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate<Subscription> { $0.isActive == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)] // 更新日が新しい順
        )
        
        guard let subscriptions = try? modelContext.fetch(fetchDescriptor),
              subscriptions.count > 1 else {
            return
        }
        
        var seenNames = Set<String>()
        var duplicatesToRemove: [Subscription] = []
        
        for subscription in subscriptions {
            let normalizedName = subscription.name
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .lowercased()
            
            if seenNames.contains(normalizedName) {
                // すでに登録されている（＝重複している古いデータ）
                duplicatesToRemove.append(subscription)
            } else {
                seenNames.insert(normalizedName)
            }
        }
        
        if duplicatesToRemove.isEmpty {
            return
        }
        
        print("🔍 重複サブスク検出: \(duplicatesToRemove.count)件を削除します。")
        
        for dup in duplicatesToRemove {
            // カレンダーイベントと通知リマインダーを確実にクリーンアップ
            let notificationID = NotificationService.makeIdentifier(
                name: dup.name, startDate: dup.startDate
            )
            NotificationService.cancelReminder(identifier: notificationID)
            NotificationService.cancelReminder(identifier: notificationID + "_trial")
            NotificationService.cancelReminder(identifier: notificationID + "_end")
            
            // 必要な情報を退避
            let name = dup.name
            let eventID = dup.calendarEventIdentifier
            let trialEventID = dup.trialCalendarEventIdentifier
            
            // カレンダーイベントの安全な非同期削除
            Task {
                await CalendarService.removeEvents(
                    name: name,
                    eventIdentifier: eventID,
                    trialEventIdentifier: trialEventID
                )
            }
            
            // SwiftDataコンテキストから削除
            modelContext.delete(dup)
        }
        
        // 即時保存
        try? modelContext.save()
    }
}
