//
//  AddSubscriptionView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData
import PhotosUI

/// 追加画面で表示するシートの種類
enum AddSubscriptionSheetType: Identifiable {
    case presetWizard
    case quickPlan(SubscriptionPreset)
    
    var id: String {
        switch self {
        case .presetWizard:
            return "presetWizard"
        case .quickPlan(let preset):
            return "quickPlan-\(preset.id.uuidString)"
        }
    }
}

/// サブスクリプション登録フォーム画面。
/// SubscriptionListView からシートとして表示される。
/// フォームセクションは SubscriptionFormSections を再利用。
struct AddSubscriptionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddSubscriptionViewModel
    @State private var activeSheet: AddSubscriptionSheetType? = nil
    @State private var isQuickAddExpanded = true
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isShowingPhotosPicker = false
    
    // キーボードフォーカス管理
    @FocusState private var focusedField: FormField?
    
    // トーストフィードバック用の状態
    @State private var showingToast = false
    @State private var toastMessage = ""

    let isModal: Bool

    init(isModal: Bool = false, onSaveSuccess: (() -> Void)? = nil) {
        self.isModal = isModal
        let vm = AddSubscriptionViewModel()
        vm.onSaveSuccess = onSaveSuccess
        _viewModel = State(initialValue: vm)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                Form {
                    // AI スクロショ解析セクション
                    Section {
                        Button {
                            // isPresented で制御する方式に変更
                            isShowingPhotosPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("スクショ・画像から自動入力")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("レシートや画面から情報を自動で抽出します")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .photosPicker(isPresented: $isShowingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    await viewModel.processScreenshot(imageData: data)
                                    withAnimation(.spring()) {
                                        proxy.scrollTo("formInputFields", anchor: .top)
                                    }
                                }
                                selectedPhotoItem = nil
                            }
                        }
                    }
                    .listRowBackground(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // 爆速クイック追加 & プリセットセクションのアコーディオン
                    Section {
                        DisclosureGroup(isExpanded: $isQuickAddExpanded) {
                            VStack(spacing: 0) {
                                quickAddGrid
                                    .padding(.top, 8)
                                
                                presetWizardButton
                                    .padding(.bottom, 8)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                Text("爆速クイック・人気サービスから追加")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // メイン入力フォームエリア
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
                        focusedField: $focusedField
                    )
                }
                .onTapGesture {
                    focusedField = nil // カーソル外タップでキーボード自動クローズ
                }
                .navigationTitle("サブスクを追加")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    if isModal {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる") { dismiss() }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            let savedName = viewModel.name
                            focusedField = nil // 保存時にキーボードを閉じる
                            Task {
                                if await viewModel.save(using: modelContext) {
                                    handleSaveSuccess(serviceName: savedName)
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
                .sheet(item: $activeSheet) { sheetType in
                    switch sheetType {
                    case .presetWizard:
                        PresetSelectionWizard { preset, plan in
                            viewModel.applyPreset(preset, plan: plan)
                            isQuickAddExpanded = false
                            // 選択時に入力フォームへ自動スクロール
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                proxy.scrollTo("formInputFields", anchor: .top)
                            }
                        }
                    case .quickPlan(let preset):
                        QuickPlanSelectionSheet(preset: preset) { plan in
                            viewModel.applyPreset(preset, plan: plan)
                            viewModel.satisfaction = 4
                            viewModel.usageFrequency = .daily
                            isQuickAddExpanded = false
                            // クイック追加時に即保存せず、フォームへ適用 ＆ 自動スクロールして微調整可能にします
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                proxy.scrollTo("formInputFields", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // プレミアムトーストオーバーレイ
            if showingToast {
                toastView
            }
            
            // 解析中のローディングオーバーレイ
            if viewModel.isAnalyzingOCR {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("画像を解析中...")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("魔法をかけています ✨")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
    }
    
    // MARK: - トースト & ヘルパー処理
    
    private func triggerToast(message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showingToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingToast = false
            }
        }
    }
    
    private func handleSaveSuccess(serviceName: String) {
        // Haptic Feedback の実行
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // トーストのトリガー
        triggerToast(message: "\(serviceName) を登録しました！")
        
        // フォームのリセット
        viewModel.reset()
    }
    
    private var toastView: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .shadow(color: .green.opacity(0.8), radius: 5)
                
                Text(toastMessage)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.5), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - プリセットUI

    private var presetWizardButton: some View {
        Button {
            activeSheet = .presetWizard
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("その他の人気サービスから自動入力する")
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - 爆速クイック追加 UI

    private let quickServices: [QuickServiceItem] = [
        QuickServiceItem(name: "Netflix", displayName: "Netflix", iconName: "film", color: Color(red: 0.898, green: 0.035, blue: 0.078), gradientColors: [Color(red: 0.898, green: 0.035, blue: 0.078), Color(red: 0.6, green: 0.0, blue: 0.05)]),
        QuickServiceItem(name: "Spotify", displayName: "Spotify", iconName: "music.note", color: Color(red: 0.114, green: 0.725, blue: 0.329), gradientColors: [Color(red: 0.114, green: 0.725, blue: 0.329), Color(red: 0.07, green: 0.55, blue: 0.24)]),
        QuickServiceItem(name: "YouTube Premium", displayName: "YouTube", iconName: "play.rectangle.fill", color: Color(red: 1.0, green: 0.0, blue: 0.0), gradientColors: [Color(red: 1.0, green: 0.0, blue: 0.0), Color(red: 0.7, green: 0.0, blue: 0.0)]),
        QuickServiceItem(name: "Amazon Prime", displayName: "Amazon Prime", iconName: "shippingbox.fill", color: Color(red: 0.0, green: 0.659, blue: 0.910), gradientColors: [Color(red: 0.0, green: 0.659, blue: 0.910), Color(red: 0.0, green: 0.48, blue: 0.69)]),
        QuickServiceItem(name: "ChatGPT", displayName: "ChatGPT", iconName: "cpu.fill", color: Color(red: 0.063, green: 0.639, blue: 0.498), gradientColors: [Color(red: 0.063, green: 0.639, blue: 0.498), Color(red: 0.04, green: 0.43, blue: 0.33)]),
        QuickServiceItem(name: "Apple Music", displayName: "Apple Music", iconName: "applelogo", color: Color(red: 0.980, green: 0.141, blue: 0.235), gradientColors: [Color(red: 0.980, green: 0.141, blue: 0.235), Color(red: 0.72, green: 0.10, blue: 0.14)])
    ]

    private var quickAddGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("爆速クイック追加 (主要サービス)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(quickServices) { service in
                    Button {
                        if let preset = SubscriptionPreset.defaultPresets.first(where: { $0.name == service.name }) {
                            activeSheet = .quickPlan(preset)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: service.iconName)
                                .font(.title3)
                                .foregroundColor(.white)
                            Text(service.displayName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: service.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: service.color.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
}

// MARK: - 爆速クイック追加用サブビュー & データ構造

struct QuickServiceItem: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let iconName: String
    let color: Color
    let gradientColors: [Color]
}

struct QuickPlanSelectionSheet: View {
    let preset: SubscriptionPreset
    let onSelect: (SubscriptionPlan) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(preset.name) のプランを選択してください。\nタップすると即座に登録が完了します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(preset.plans) { plan in
                            Button {
                                onSelect(plan)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(plan.billingCycle.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(CurrencyHelper.formatted(amount: plan.amount))
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.accentColor)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("\(preset.name) クイック追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
