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
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EditSubscriptionViewModel
    @State private var showingDeleteConfirm = false
    
    // キーボードフォーカス管理
    @FocusState private var focusedField: FormField?

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
                    ownSharePercentage: $viewModel.ownSharePercentage,
                    paymentMethod: $viewModel.paymentMethod,
                    isNotificationEnabled: $viewModel.isNotificationEnabled,
                    isExpense: $viewModel.isExpense,
                    focusedField: $focusedField
                )
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("このサブスクリプションを削除")
                            Spacer()
                        }
                    }
                }
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
                        focusedField = nil // 保存時にキーボードを閉じる
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        focusedField = nil // キーボードの完了ボタン
                    }
                }
            }
            .alert("サブスクリプションの削除", isPresented: $showingDeleteConfirm) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    viewModel.delete(using: modelContext)
                    dismiss()
                }
            } message: {
                Text("本当に「\(viewModel.name)」を削除しますか？この操作は元に戻せません。")
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
