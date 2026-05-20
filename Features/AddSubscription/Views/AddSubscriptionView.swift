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
    @State private var showingPresetWizard = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // プリセット起動ボタン
                presetWizardButton

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
                    notes: $viewModel.notes
                )
                }
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
        .sheet(isPresented: $showingPresetWizard) {
            PresetSelectionWizard { preset, plan in
                viewModel.applyPreset(preset, plan: plan)
            }
        }
    }
    
    // MARK: - プリセットUI

    private var presetWizardButton: some View {
        Button {
            showingPresetWizard = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("人気のサービスから自動入力する")
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
