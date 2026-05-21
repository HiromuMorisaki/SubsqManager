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
    
    /// 復元対象の履歴（シート起動トリガー）
    @State private var restoringHistory: ReductionHistory? = nil
    
    var body: some View {
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
                                    restoringHistory = history
                                } label: {
                                    Label("復元", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)
                            }
                    }
                }
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
        .sheet(item: $restoringHistory) { history in
            AddSubscriptionView(reductionHistory: history) {
                // プレフィルされたフォームから新規保存が成功したタイミングで削減履歴から削除
                withAnimation {
                    modelContext.delete(history)
                    try? modelContext.save()
                }
            }
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
        }
    }
}
