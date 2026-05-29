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
    case bulkImport
    
    var id: String {
        switch self {
        case .presetWizard:
            return "presetWizard"
        case .quickPlan(let preset):
            return "quickPlan-\(preset.id)"
        case .bulkImport:
            return "bulkImport"
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
    
    // Proアップグレードシート表示フラグ
    @State private var showingProUpgradeSheet = false

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
                                    
                                    // 💡 一括検出されたデータがある場合は、一括インポートプレビューシートを表示
                                    if !viewModel.parsedBulkItems.isEmpty {
                                        activeSheet = .bulkImport
                                    } else {
                                        withAnimation(.spring()) {
                                            proxy.scrollTo("formInputFields", anchor: .top)
                                        }
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
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isQuickAddExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.yellow)
                                    Text("爆速クイック・人気サービスから追加")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(isQuickAddExpanded ? 90 : 0))
                                }
                                .padding(.vertical, 12)
                                .contentShape(Rectangle()) // 行全体をタップ可能にする
                            }
                            .buttonStyle(.plain)
                            
                            if isQuickAddExpanded {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                quickAddGrid
                                    .padding(.top, 4)
                                
                                presetWizardButton
                                    .padding(.bottom, 8)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
                        paymentMethod: $viewModel.paymentMethod,
                        isNotificationEnabled: $viewModel.isNotificationEnabled,
                        isExpense: $viewModel.isExpense,
                        focusedField: $focusedField
                    )
                }
                // Pickerのタップを吸い込んでしまう不具合を解消するため、onTapGestureを削除
                // 代わりにスクロール時のキーボード非表示を有効化
                .scrollDismissesKeyboard(.interactively)
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
                            focusedField = nil // 保存時にキーボードを閉じる
                            
                            // 現在のアクティブ登録数をSwiftDataから直接フェッチカウント
                            let activeCount = (try? modelContext.fetchCount(FetchDescriptor<Subscription>(predicate: #Predicate<Subscription> { $0.isActive == true }))) ?? 0
                            
                            if !ProManager.shared.isProUnlocked && activeCount >= 10 {
                                // 10件上限エラー。保存をブロックしProプラン紹介シートを表示
                                showingProUpgradeSheet = true
                            } else {
                                let savedName = viewModel.name
                                Task {
                                    if await viewModel.save(using: modelContext) {
                                        handleSaveSuccess(serviceName: savedName, shouldRequestReview: true)
                                    }
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
                    case .bulkImport:
                        BulkImportPreviewSheet(initialItems: viewModel.parsedBulkItems) {
                            let count = viewModel.parsedBulkItems.count
                            handleSaveSuccess(serviceName: "\(count)件のサブスク", shouldRequestReview: false)
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingProUpgradeSheet) {
                    ProUpgradeSheet()
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
    
    private func handleSaveSuccess(serviceName: String, shouldRequestReview: Bool = true) {
        // Haptic Feedback の実行
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // トーストのトリガー
        triggerToast(message: "\(serviceName) を登録しました！")
        
        // App Storeレビュー要求（Aha! Moment - サブスク登録成功時）
        if shouldRequestReview {
            ReviewRequestService.shared.requestReviewIfSubscriptionAdded()
        }
        
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

// MARK: - BulkImportPreviewSheet

struct BulkImportPreviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// 親View（AddSubscriptionView）を閉じるためのクロージャ
    let onImportSuccess: () -> Void
    
    /// 検出されたサブスクデータの初期リスト
    let initialItems: [ParsedBulkItem]
    
    /// ユーザーがインライン編集する状態を保持するリスト
    @State private var items: [ParsedBulkItem] = []
    
    /// 選択（インポート対象）されているアイテムのIDセット
    @State private var selectedItemIds: Set<UUID> = []
    
    /// Proアップグレードシート表示フラグ
    @State private var showingProUpgradeSheet = false
    
    /// エラーアラート表示用
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    init(initialItems: [ParsedBulkItem], onImportSuccess: @escaping () -> Void) {
        self.initialItems = initialItems
        self.onImportSuccess = onImportSuccess
        // 初期状態で編集用Stateにコピー
        _items = State(initialValue: initialItems)
        // 初期状態では全選択
        _selectedItemIds = State(initialValue: Set(initialItems.map { $0.id }))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - ガイドテキスト
                Text("検出されたサブスクリプションを確認・修正してください。\nチェックされた項目が一括で登録されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                // MARK: - サマリーヘッダー (Summary Header)
                let activeImportCount = items.filter { !$0.isCancelled }.count
                let cancelledImportCount = items.filter { $0.isCancelled }.count
                
                HStack {
                    Spacer()
                    Text("アクティブ \(activeImportCount) 件 / 解約済み \(cancelledImportCount) 件 を検出 ✨")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.bottom, 8)
                
                // MARK: - リスト表示
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($items) { $item in
                            cardView(for: $item)
                        }
                    }
                    .padding()
                }
                
                // MARK: - フッター（一括登録ボタン ＆ 10件制限連動）
                VStack(spacing: 12) {
                    let selectedCount = selectedItemIds.count
                    let activeCount = (try? modelContext.fetchCount(FetchDescriptor<Subscription>(predicate: #Predicate<Subscription> { $0.isActive == true }))) ?? 0
                    let totalCountAfterImport = activeCount + selectedCount
                    let isLimitExceeded = !ProManager.shared.isProUnlocked && totalCountAfterImport > 10
                    let isButtonDisabled = selectedCount == 0
                    
                    if isLimitExceeded {
                        // 10件制限に引っかかる場合の説明
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("登録数が無料枠の上限（10件）を超えます。")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
                    
                    Button {
                        if isLimitExceeded {
                            // 制限超過：Proハーフシートを表示してインポートをブロック
                            showingProUpgradeSheet = true
                        } else {
                            // 通常実行
                            executeImport()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(isLimitExceeded 
                                 ? "Proプランにアップグレードして一括登録" 
                                 : "\(selectedCount)件のサブスクを一括登録する ✨")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isButtonDisabled 
                                    ? Color.gray 
                                    : (isLimitExceeded ? Color.orange : Color.accentColor))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: (isButtonDisabled ? Color.gray : (isLimitExceeded ? Color.orange : Color.accentColor)).opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(isButtonDisabled)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("一括インポート")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .sheet(isPresented: $showingProUpgradeSheet) {
                ProUpgradeSheet()
            }
            .alert("インポートエラー", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // 重複チェックを行い、登録済みのものは選択を解除する
                let existingSubs = (try? modelContext.fetch(FetchDescriptor<Subscription>())) ?? []
                var initialSelected = Set(items.map { $0.id })
                
                for item in items {
                    let isDuplicate = existingSubs.contains { existing in
                        existing.name.trimmingCharacters(in: .whitespaces).localizedCaseInsensitiveCompare(item.name.trimmingCharacters(in: .whitespaces)) == .orderedSame
                    }
                    if isDuplicate {
                        initialSelected.remove(item.id)
                    }
                }
                selectedItemIds = initialSelected
            }
        }
    }
    
    // MARK: - 個別カードビュー (インライン編集可能)
    
    private func cardView(for item: Binding<ParsedBulkItem>) -> some View {
        let isSelected = selectedItemIds.contains(item.wrappedValue.id)
        
        let existingSubs = (try? modelContext.fetch(FetchDescriptor<Subscription>())) ?? []
        let isDuplicate = existingSubs.contains { existing in
            existing.name.trimmingCharacters(in: .whitespaces).localizedCaseInsensitiveCompare(item.wrappedValue.name.trimmingCharacters(in: .whitespaces)) == .orderedSame
        }
        
        let cardBackground = item.wrappedValue.isCancelled
            ? Color(.systemGroupedBackground)
            : Color(.secondarySystemGroupedBackground)
            
        let cardBorderColor: Color = {
            if !isSelected {
                return .clear
            } else if item.wrappedValue.isCancelled {
                return .gray.opacity(0.25)
            } else {
                return Color.accentColor.opacity(0.2)
            }
        }()
        
        let cardOpacity: Double = {
            if !isSelected {
                return 0.45
            } else if item.wrappedValue.isCancelled {
                return 0.8
            } else {
                return 1.0
            }
        }()
        
        return VStack(alignment: .leading, spacing: 12) {
            // ヘッダー（選択チェックボックス ＆ サービス名）
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        if isSelected {
                            selectedItemIds.remove(item.wrappedValue.id)
                        } else {
                            selectedItemIds.insert(item.wrappedValue.id)
                        }
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                
                // アイコン
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.wrappedValue.iconName)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                
                // サービス名（直接編集可能）
                TextField("サービス名", text: item.name)
                    .font(.headline)
                    .textFieldStyle(.plain)
                
                Spacer()
                
                // 重複登録済み警告マーク
                if isDuplicate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("登録済")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)
                }
                
                // 金額未検出の場合の警告マーク
                if item.wrappedValue.isAmountEstimated {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("推測")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)
                }
                
                // 解約済みフラグのバッジ
                if item.wrappedValue.isCancelled {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                        Text("解約済")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // 金額 ＆ 周期 ＆ 日付のインライン入力グリッド
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                // 金額行
                GridRow {
                    Text("金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("¥")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // インライン金額のバインディング（Decimal ↔ String 相互変換ブリッジ）
                        TextField("金額", text: Binding(
                            get: {
                                item.wrappedValue.amount == 0 ? "" : NSDecimalNumber(decimal: item.wrappedValue.amount).stringValue
                            },
                            set: { newValue in
                                let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                                item.wrappedValue.amount = Decimal(string: cleaned) ?? 0
                            }
                        ))
                        .font(.body)
                        .keyboardType(.numberPad)
                        .bold()
                        .frame(width: 90)
                    }
                    
                    // 請求周期のPicker
                    Picker("周期", selection: item.billingCycle) {
                        Text("月額").tag(BillingCycle.monthly)
                        Text("年額").tag(BillingCycle.yearly)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                }
                
                // 次回請求日行
                GridRow {
                    Text("請求日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker(
                        "",
                        selection: item.nextPaymentDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    Spacer()
                }
                
                // トライアル行
                GridRow {
                    Text("トライアル")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Toggle("無料トライアル", isOn: item.hasTrial)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        
                        if item.wrappedValue.hasTrial {
                            Text("終了:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            DatePicker(
                                "",
                                selection: item.trialEndDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                        }
                    }
                    .gridCellColumns(2)
                }
                
                // 満足度★評価行
                GridRow {
                    Text("満足度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= item.wrappedValue.satisfaction ? "star.fill" : "star")
                                .font(.body)
                                .foregroundColor(star <= item.wrappedValue.satisfaction ? .yellow : .gray.opacity(0.3))
                                .onTapGesture {
                                    if isSelected {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            item.wrappedValue.satisfaction = star
                                        }
                                    }
                                }
                        }
                    }
                    .gridCellColumns(2)
                }
            }
            .disabled(!isSelected) // 非選択時は編集不可にする
            
            // インライン警告
            if isSelected && item.wrappedValue.amount <= 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text("金額を正しく入力してください")
                        .font(.caption2)
                }
                .foregroundColor(.red)
                .transition(.opacity)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(item.wrappedValue.isCancelled ? 0.01 : 0.03), radius: 5, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorderColor, lineWidth: 1.5)
        )
        .opacity(cardOpacity)
    }
    
    // MARK: - インポートの実行処理
    
    private func executeImport() {
        // 選択されたアイテムのみを抽出
        let itemsToImport = items.filter { selectedItemIds.contains($0.id) }
        
        guard !itemsToImport.isEmpty else { return }
        
        // 金額バリデーション
        for item in itemsToImport {
            if item.amount <= 0 {
                alertMessage = "「\(item.name)」の金額が正しく入力されていません。0円以上の金額を入力してください。"
                showingErrorAlert = true
                return
            }
        }
        
        Task { @MainActor in
            for item in itemsToImport {
                let calendar = Calendar.current
                
                // 開始日の計算: 更新日または有効期限の1ヶ月前 (月額) または1年前 (年額) に設定
                let dateComponentsValue = -1
                let dateComponent = item.billingCycle == .yearly ? Calendar.Component.year : Calendar.Component.month
                let calculatedStartDate = calendar.date(byAdding: dateComponent, value: dateComponentsValue, to: item.nextPaymentDate) ?? item.nextPaymentDate
                
                // 有効期限判定 (解約済みの場合)
                let endDate: Date? = item.isCancelled ? item.nextPaymentDate : nil
                
                // ユーザーの要望に基づき、解約済みの場合は即座に非アクティブ（isActive = false）にして合計金額に換算しないようにする
                let isActive = !item.isCancelled
                
                let subscription = Subscription(
                    name: item.name.trimmingCharacters(in: .whitespaces),
                    amount: item.amount,
                    billingCycle: item.billingCycle,
                    category: item.category, // ★ プリセットから取得したカテゴリを設定！
                    startDate: calculatedStartDate, // 計算された開始日を設定
                    iconName: item.iconName,
                    notes: item.isCancelled ? "Apple ID 一括インポート (解約済み)" : "Apple ID 一括インポート",
                    isActive: isActive, // アクティブ状態を設定
                    trialEndDate: item.hasTrial ? item.trialEndDate : nil,
                    endDate: endDate, // 解約済みの場合は終了日を設定
                    satisfaction: item.satisfaction, // 満足度★評価をバインドして保存
                    isNotificationEnabled: !item.isCancelled // 解約済みの場合は通知をデフォルトOFFにする
                )
                
                // 次回請求日をアサイン
                subscription.nextPaymentDate = item.nextPaymentDate
                
                modelContext.insert(subscription)
                
                // 通知のスケジュール (アクティブで通知が有効な場合のみ)
                if subscription.isNotificationEnabled && isActive {
                    let notificationID = NotificationService.makeIdentifier(
                        name: subscription.name, startDate: subscription.startDate
                    )
                    let leadDays = UserDefaults.standard.integer(forKey: "notificationLeadDays")
                    let actualLeadDays = leadDays > 0 ? leadDays : 1
                    
                    await NotificationService.scheduleReminder(
                        subscriptionName: subscription.name,
                        nextPaymentDate: subscription.nextPaymentDate,
                        identifier: notificationID,
                        leadDays: actualLeadDays
                    )
                }
                
                // カレンダー同期 (アクティブな場合のみ同期)
                if isActive && UserDefaults.standard.bool(forKey: "calendarSyncEnabled") {
                    await CalendarService.syncSubscription(subscription)
                }
            }
            
            // Haptic Feedback
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            
            // 成功クロージャを呼び出し、シートを閉じる
            onImportSuccess()
            dismiss()
        }
    }
}
