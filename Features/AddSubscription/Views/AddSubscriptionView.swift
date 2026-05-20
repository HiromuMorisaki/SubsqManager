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
struct AddSubscriptionView: View {

    /// SwiftDataの操作コンテキスト（保存時に使用）
    @Environment(\.modelContext) private var modelContext

    /// dismiss: シートを閉じるためのアクション。
    /// iOS 15以降で使用可能。presentationMode.wrappedValue.dismiss() の後継。
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddSubscriptionViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                billingSection
                categorySection
                iconSection
                notesSection
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

    // MARK: - セクション

    /// サブスク名と金額の入力セクション
    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("サブスク名", text: $viewModel.name)
            TextField("金額", text: $viewModel.amountText)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
        }
    }

    /// 請求サイクルと開始日の設定セクション
    private var billingSection: some View {
        Section("請求設定") {
            Picker("請求サイクル", selection: $viewModel.billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.displayName).tag(cycle)
                }
            }
            DatePicker("開始日", selection: $viewModel.startDate, displayedComponents: .date)
        }
    }

    /// カテゴリ選択セクション
    private var categorySection: some View {
        Section("カテゴリ") {
            Picker("カテゴリ", selection: $viewModel.category) {
                ForEach(Category.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                }
            }
        }
    }

    /// アイコン選択セクション（SF Symbolから選択）
    private var iconSection: some View {
        Section("アイコン") {
            Picker("アイコン", selection: $viewModel.iconName) {
                ForEach(Self.availableIcons, id: \.self) { icon in
                    Label(icon, systemImage: icon).tag(icon)
                }
            }
        }
    }

    /// メモ入力セクション
    private var notesSection: some View {
        Section("メモ") {
            TextField("メモ（任意）", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - 定数

    /// アイコン選択肢として表示するSF Symbol名のリスト
    private static let availableIcons: [String] = [
        "creditcard", "tv", "music.note", "film",
        "gamecontroller", "book", "newspaper",
        "cloud", "wifi", "desktopcomputer",
        "briefcase", "heart", "star"
    ]
}

// MARK: - Preview

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
