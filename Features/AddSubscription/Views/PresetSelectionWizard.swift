//
//  PresetSelectionWizard.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// ジャンル → サービス → プラン を選択するウィザード
struct PresetSelectionWizard: View {
    @Environment(\.dismiss) private var dismiss
    
    /// 選択が完了した時に呼ばれるクロージャ (選択されたサービス, 選択されたプラン)
    var onSelect: (SubscriptionPreset, SubscriptionPlan) -> Void
    
    // カテゴリごとのプリセットデータ
    private let groupedPresets = SubscriptionPreset.groupedByCategory

    var body: some View {
        NavigationStack {
            List {
                // Category.allCasesの順に表示する（定義順）
                ForEach(Category.allCases, id: \.self) { category in
                    let presets = groupedPresets[category] ?? []
                    NavigationLink {
                        ServiceSelectionView(
                            category: category,
                            presets: presets,
                            onSelect: { preset, plan in
                                onSelect(preset, plan)
                                dismiss()
                            }
                        )
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: category.iconName)
                                .font(.title2)
                                .foregroundStyle(category.color)
                                .frame(width: 32)
                            
                            Text(category.displayName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(presets.count)件")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("ジャンルを選ぶ")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 450)
        #endif
    }
}

/// ステップ2: サービスを選択する画面
private struct ServiceSelectionView: View {
    let category: Category
    let presets: [SubscriptionPreset]
    let onSelect: (SubscriptionPreset, SubscriptionPlan) -> Void
    
    @Query private var subscriptions: [Subscription]
    
    private func isSubscribed(_ preset: SubscriptionPreset) -> Bool {
        subscriptions.contains { $0.name.localizedCaseInsensitiveContains(preset.name) }
    }
    
    var body: some View {
        List {
            ForEach(presets) { preset in
                let subscribed = isSubscribed(preset)
                
                if preset.plans.count == 1, let singlePlan = preset.plans.first {
                    // プランが1つしかない場合は即座に選択
                    Button {
                        onSelect(preset, singlePlan)
                    } label: {
                        ServiceRowView(preset: preset, isSubscribed: subscribed)
                            .contentShape(Rectangle()) // 全体をタップ可能にする
                    }
                    .buttonStyle(.plain) // Macでの不要なボタン背景を消去
                } else {
                    // 複数のプランがある場合はNavigationLinkで遷移
                    NavigationLink {
                        PlanSelectionView(preset: preset, onSelect: onSelect)
                    } label: {
                        ServiceRowView(preset: preset, isSubscribed: subscribed)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("サービスを選ぶ")
    }
}

/// サービスの一覧行ビュー
private struct ServiceRowView: View {
    let preset: SubscriptionPreset
    let isSubscribed: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: preset.iconName)
                .font(.title)
                .foregroundStyle(preset.category.color.gradient)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("\(preset.plans.count)種類のプラン")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSubscribed {
                Text("契約中")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .opacity(isSubscribed ? 0.6 : 1.0)
    }
}

/// ステップ3: プランを選択する画面
private struct PlanSelectionView: View {
    let preset: SubscriptionPreset
    let onSelect: (SubscriptionPreset, SubscriptionPlan) -> Void
    
    var body: some View {
        List {
            ForEach(preset.plans) { plan in
                Button {
                    onSelect(preset, plan)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("\(formatAmount(plan.amount)) / \(plan.billingCycle.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain) // Macでの不要なボタン背景を消去
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle("\(preset.name)のプラン")
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(for: amount) ?? "\(amount)"
    }
}

#Preview {
    PresetSelectionWizard { preset, plan in
        print("Selected: \(preset.name) - \(plan.name)")
    }
}
