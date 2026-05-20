//
//  PastSubscriptionsView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// 過去契約していた（解約済みの）サブスクリプションを一覧表示する画面。
struct PastSubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // isActive が false のものを取得
    @Query(
        filter: #Predicate<Subscription> { $0.isActive == false },
        sort: \Subscription.updatedAt,
        order: .reverse
    ) private var pastSubscriptions: [Subscription]
    
    var body: some View {
        Group {
            if pastSubscriptions.isEmpty {
                ContentUnavailableView(
                    "過去のサブスクはありません",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("解約したサブスクリプションはここに表示されます。")
                )
            } else {
                List {
                    ForEach(pastSubscriptions) { sub in
                        pastSubscriptionRow(sub)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(sub)
                                } label: {
                                    Label("完全に削除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    restore(sub)
                                } label: {
                                    Label("復元", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
        }
        .navigationTitle("過去のサブスク")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func pastSubscriptionRow(_ sub: Subscription) -> some View {
        HStack {
            Image(systemName: sub.iconName)
                .font(.title2)
                .foregroundStyle(.gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sub.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(sub.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyHelper.formatted(amount: sub.amount))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func restore(_ sub: Subscription) {
        withAnimation {
            sub.isActive = true
            sub.updatedAt = Date()
            
            // 復元時に通知を再スケジュールする処理を入れることも可能
            sub.updateNextPaymentDate()
            Task {
                let notificationID = NotificationService.makeIdentifier(name: sub.name, startDate: sub.startDate)
                await NotificationService.scheduleReminder(
                    subscriptionName: sub.name,
                    nextPaymentDate: sub.nextPaymentDate,
                    identifier: notificationID
                )
            }
        }
    }
    
    private func delete(_ sub: Subscription) {
        withAnimation {
            modelContext.delete(sub)
        }
    }
}
