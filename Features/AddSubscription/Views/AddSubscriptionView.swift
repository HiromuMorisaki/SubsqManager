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
            VStack(spacing: 0) {
                // プリセット選択カルーセル
                presetCarousel

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
    // MARK: - プリセットUI

    private var presetCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubscriptionPreset.defaultPresets) { preset in
                    Button {
                        withAnimation {
                            viewModel.applyPreset(preset)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: preset.iconName)
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 50, height: 50)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                            
                            Text(preset.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Preview

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
