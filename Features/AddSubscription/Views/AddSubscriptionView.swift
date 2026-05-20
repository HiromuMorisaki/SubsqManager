//
//  AddSubscriptionView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// サブスクリプション登録フォーム画面。
/// SubscriptionListView からシートとして表示される。
/// フォームセクションは SubscriptionFormSections を再利用。
struct AddSubscriptionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddSubscriptionViewModel()

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
                    iconName: $viewModel.iconName,
                    notes: $viewModel.notes
                )
            }
            .navigationTitle("サブスクを追加")
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
                            if await viewModel.save(using: modelContext) {
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
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
