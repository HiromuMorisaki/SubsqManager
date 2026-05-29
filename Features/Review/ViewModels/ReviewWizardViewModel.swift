//
//  ReviewWizardViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

@Observable
final class ReviewWizardViewModel {
    /// 見直し対象のサブスクリプションリスト（アクティブなもの）
    var subscriptions: [Subscription] = []
    
    /// 現在表示しているサブスクのインデックス
    var currentIndex: Int = 0
    
    /// 見直しがすべて完了してサマリー画面を表示するかどうか
    var isFinished: Bool = false
    
    /// 完了時に呼び出されるアクション
    var onFinish: (() -> Void)?
    
    /// 指定された配列でウィザードを開始する
    func start(with subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
        self.currentIndex = 0
        self.isFinished = subscriptions.isEmpty
    }
    
    /// 現在のサブスクに対してステータスを判定して次のカードへ進む
    func markCurrent(as status: ReviewStatus) {
        guard currentIndex < subscriptions.count else { return }
        
        let currentSub = subscriptions[currentIndex]
        currentSub.reviewStatus = status
        currentSub.updatedAt = Date() // SwiftDataに変更を通知するため
        
        moveToNext()
    }
    
    /// 次のカードへ進む。最後まで到達したら完了フラグを立てる
    private func moveToNext() {
        if currentIndex < subscriptions.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
            onFinish?()
        }
    }
    
    // MARK: - サマリー計算用
    
    /// 現在の「解約候補」に分類されたサブスクリプションのリスト
    var cancelCandidates: [Subscription] {
        subscriptions.filter { $0.reviewStatus == .cancelCandidate }
    }
    
    /// 解約候補をすべて解約した場合の「月額」節約額
    var potentialMonthlySavings: Decimal {
        cancelCandidates.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
    }
    
    /// 解約候補をすべて解約した場合の「年額」節約額
    var potentialYearlySavings: Decimal {
        cancelCandidates.reduce(Decimal.zero) { $0 + $1.yearlyAmount }
    }
    
    /// 解約候補を一括で解約し、削減履歴に記録して元のサブスクを物理削除する
    func confirmCancellations(using modelContext: ModelContext) {
        for sub in cancelCandidates {
            let history = ReductionHistory(
                name: sub.name,
                amount: sub.amount,
                billingCycle: sub.billingCycle,
                category: sub.category,
                cancelledDate: Date(),
                iconName: sub.iconName,
                originalMemo: sub.notes.isEmpty ? nil : sub.notes
            )
            modelContext.insert(history)

            let notificationID = NotificationService.makeIdentifier(name: sub.name, startDate: sub.startDate)
            NotificationService.cancelReminder(identifier: notificationID)
            NotificationService.cancelReminder(identifier: notificationID + "_trial")
            NotificationService.cancelReminder(identifier: notificationID + "_end")

            // 必要な情報を退避
            let name = sub.name
            let eventID = sub.calendarEventIdentifier
            let trialEventID = sub.trialCalendarEventIdentifier

            // カレンダーイベントの削除
            Task {
                await CalendarService.removeEvents(
                    name: name,
                    eventIdentifier: eventID,
                    trialEventIdentifier: trialEventID
                )
            }

            modelContext.delete(sub)
        }
        
        do {
            try modelContext.save()
            WidgetDataShareHelper.updateSharedSavingsAmount(using: modelContext)
        } catch {
            print("Failed to save cancellations in ReviewWizard: \(error)")
        }
    }
}
