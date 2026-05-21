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
    
    @State private var searchText = ""
    
    // グリッドの列定義 (2列)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // 検索ワードに合致する全プリセット
    private var filteredAllPresets: [SubscriptionPreset] {
        if searchText.isEmpty {
            return []
        }
        return SubscriptionPreset.defaultPresets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if searchText.isEmpty {
                        // 通常のグリッド表示
                        Text("ジャンルから探す")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
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
                                    CategoryGridCard(category: category, count: presets.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // リアルタイム検索結果の表示
                        if filteredAllPresets.isEmpty {
                            ContentUnavailableView(
                                "サービスが見つかりません",
                                systemImage: "magnifyingglass",
                                description: Text("\"\(searchText)\" に一致するプリセットはありません")
                            )
                        } else {
                            Text("検索結果 (\(filteredAllPresets.count)件)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(filteredAllPresets) { preset in
                                    NavigationLink {
                                        PlanSelectionView(preset: preset, onSelect: { selectedPreset, selectedPlan in
                                            onSelect(selectedPreset, selectedPlan)
                                            dismiss()
                                        })
                                    } label: {
                                        SearchResultRow(preset: preset)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("サブスクを追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .searchable(text: $searchText, prompt: "200以上のサービスから検索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }
}

/// カテゴリを表示するグリッドカードUI
private struct CategoryGridCard: View {
    let category: Category
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン背景をカテゴリカラーのグラデーションに
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.iconName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(count)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

/// 検索結果の1行ビュー
private struct SearchResultRow: View {
    let preset: SubscriptionPreset
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(preset.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: preset.iconName)
                    .font(.body)
                    .foregroundStyle(preset.category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(preset.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(preset.category.color.opacity(0.1))
                    .foregroundStyle(preset.category.color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
    }
}

/// ステップ2: サービスを選択する画面
private struct ServiceSelectionView: View {
    let category: Category
    let presets: [SubscriptionPreset]
    let onSelect: (SubscriptionPreset, SubscriptionPlan) -> Void
    
    @Query private var subscriptions: [Subscription]
    @State private var innerSearchText = ""
    
    private func isSubscribed(_ preset: SubscriptionPreset) -> Bool {
        subscriptions.contains { $0.name.localizedCaseInsensitiveContains(preset.name) }
    }
    
    // カテゴリ内での検索フィルタリング
    private var filteredPresets: [SubscriptionPreset] {
        if innerSearchText.isEmpty {
            return presets
        }
        return presets.filter { $0.name.localizedCaseInsensitiveContains(innerSearchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredPresets) { preset in
                let subscribed = isSubscribed(preset)
                
                if preset.plans.count == 1, let singlePlan = preset.plans.first {
                    // プランが1つしかない場合は即座に選択
                    Button {
                        onSelect(preset, singlePlan)
                    } label: {
                        ServiceRowView(preset: preset, isSubscribed: subscribed)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
        .navigationTitle(category.displayName)
        .searchable(text: $innerSearchText, prompt: "\(category.displayName)内を検索")
    }
}

/// サービスの一覧行ビュー
private struct ServiceRowView: View {
    let preset: SubscriptionPreset
    let isSubscribed: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(preset.category.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: preset.iconName)
                    .font(.title3)
                    .foregroundStyle(preset.category.color)
            }
            
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
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .opacity(isSubscribed ? 0.6 : 1.0)
    }
}

/// ステップ3: プランを選択する画面
private struct PlanSelectionView: View {
    let preset: SubscriptionPreset
    let onSelect: (SubscriptionPreset, SubscriptionPlan) -> Void
    
    var body: some View {
        List {
            Section {
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
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(preset.category.color)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("プランを選択してください")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle(preset.name)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(for: amount) ?? "¥\(amount)"
    }
}

#Preview {
    PresetSelectionWizard { preset, plan in
        print("Selected: \(preset.name) - \(plan.name)")
    }
}
