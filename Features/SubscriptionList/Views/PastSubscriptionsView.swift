//
//  PastSubscriptionsView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// 過去に削減（解約）したサブスクリプションの削減履歴を一覧表示する画面。
struct PastSubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 削減履歴を解約日の降順で取得
    @Query(
        sort: \ReductionHistory.cancelledDate,
        order: .reverse
    ) private var reductionHistories: [ReductionHistory]
    
    /// 一括削除の確認アラート表示フラグ
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if reductionHistories.isEmpty {
                    ContentUnavailableView(
                        "削減履歴はありません",
                        systemImage: "sparkles",
                        description: Text("削減（解約）したサブスクリプションはここに表示されます。")
                    )
                } else {
                    List {
                        ForEach(reductionHistories) { history in
                            reductionHistoryRow(history)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        delete(history)
                                    } label: {
                                        Label("完全に削除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        Task {
                                            await restoreHistory(history)
                                        }
                                    } label: {
                                        Label("復元", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }
            
            if !reductionHistories.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.subheadline)
                            Text("削減履歴を一括削除")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.85), Color.orange.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .background(.background)
            }
        }
        .navigationTitle("削減履歴")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !reductionHistories.isEmpty {
                    Button {
                        shareCumulativeSavings()
                    } label: {
                        Label("実績をシェア", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert("削減履歴を一括削除しますか？", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除する", role: .destructive) {
                deleteAllHistory()
            }
        } message: {
            Text("すべて削除すると、これまでの累計削減金額の実績値もリセットされて消えてしまいますが、よろしいですか？")
        }
    }
    
    // MARK: - 累積集計とSNSシェア
    
    private var totalYearlySavings: Decimal {
        reductionHistories.reduce(0) { $0 + $1.yearlyAmount }
    }
    
    private var totalMonthlySavings: Decimal {
        reductionHistories.reduce(0) { $0 + $1.monthlyAmount }
    }
    
    @MainActor
    private func shareCumulativeSavings() {
        #if os(iOS)
        let card = ShareSavingsCard(
            title: "コテサクでこれだけ削減！\n累計の固定費をカットしました",
            yearlySavings: totalYearlySavings,
            monthlySavings: totalMonthlySavings,
            serviceCount: reductionHistories.count
        )
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // 高解像度での画像出力用
        
        if let image = renderer.uiImage {
            shareImage(image)
        }
        #else
        shareImage("dummy")
        #endif
    }
    
    private func reductionHistoryRow(_ history: ReductionHistory) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: history.iconName)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(history.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(history.category.displayName)
                    Text("•")
                    Text("\(history.cancelledDate, format: .dateTime.month().day()) に削減")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyHelper.formatted(amount: history.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(history.billingCycle.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func delete(_ history: ReductionHistory) {
        withAnimation {
            modelContext.delete(history)
            try? modelContext.save()
            WidgetDataShareHelper.updateSharedSavingsAmount(using: modelContext)
        }
    }
    
    private func deleteAllHistory() {
        withAnimation {
            for history in reductionHistories {
                modelContext.delete(history)
            }
            try? modelContext.save()
            WidgetDataShareHelper.updateSharedSavingsAmount(using: modelContext)
        }
    }
    
    @MainActor
    private func restoreHistory(_ history: ReductionHistory) async {
        let subscription = Subscription(
            name: history.name,
            amount: history.amount,
            billingCycle: history.billingCycle,
            category: history.category,
            startDate: Date(),
            iconName: history.iconName,
            notes: history.originalMemo ?? "",
            satisfaction: 3,
            monthlyUsageCount: UsageFrequency.daily.monthlyEstimatedCount,
            usageFrequencyRawValue: UsageFrequency.daily.rawValue
        )
        
        subscription.updateNextPaymentDate()
        modelContext.insert(subscription)
        
        let notificationID = NotificationService.makeIdentifier(
            name: subscription.name, startDate: subscription.startDate
        )
        let leadDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
        let actualLeadDays = leadDays > 0 ? leadDays : 1

        await NotificationService.scheduleReminder(
            subscriptionName: subscription.name,
            nextPaymentDate: subscription.nextPaymentDate,
            identifier: notificationID,
            leadDays: actualLeadDays
        )

        if UserDefaults.standard.bool(forKey: "calendarSyncEnabled") {
            await CalendarService.syncSubscription(subscription)
        }
        
        withAnimation {
            modelContext.delete(history)
            try? modelContext.save()
            WidgetDataShareHelper.updateSharedSavingsAmount(using: modelContext)
            // Haptic Feedback
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
    }
}
