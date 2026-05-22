//
//  EditSubscriptionView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// サブスクリプション編集画面。
/// SubscriptionListView から行タップでシート表示される。
/// フォームセクションは AddSubscriptionView と共通の SubscriptionFormSections を使用。
struct EditSubscriptionView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditSubscriptionViewModel

    /// 編集対象の Subscription を受け取ってViewModelを初期化する。
    init(subscription: Subscription) {
        _viewModel = State(
            initialValue: EditSubscriptionViewModel(subscription: subscription)
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                SubscriptionFormSections(
                    name: $viewModel.name,
                    amountText: $viewModel.amountText,
                    billingCycle: $viewModel.billingCycle,
                    category: $viewModel.category,
                    startDate: $viewModel.startDate,
                    hasTrial: $viewModel.hasTrial,
                    trialEndDate: $viewModel.trialEndDate,
                    hasEndDate: $viewModel.hasEndDate,
                    endDate: $viewModel.endDate,
                    iconName: $viewModel.iconName,
                    notes: $viewModel.notes,
                    satisfaction: $viewModel.satisfaction,
                    usageFrequency: $viewModel.usageFrequency,
                    isShared: $viewModel.isShared,
                    splitCount: $viewModel.splitCount,
                    ownSharePercentage: $viewModel.ownSharePercentage
                )
            }
            .navigationTitle("サブスクを編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // プレビュー用にダミーデータを作成
    let subscription = Subscription(
        name: "Netflix",
        amount: Decimal(1490),
        billingCycle: .monthly,
        category: .entertainment,
        startDate: Date()
    )
    EditSubscriptionView(subscription: subscription)
        .modelContainer(for: Subscription.self, inMemory: true)
}
