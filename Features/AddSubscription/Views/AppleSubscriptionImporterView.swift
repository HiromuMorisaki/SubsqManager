//
//  AppleSubscriptionImporterView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/23.
//

import SwiftUI
import SwiftData

/// Apple IDのサブスクリプション情報と連携（インポート）するためのアシスタント画面
struct AppleSubscriptionImporterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // インポート選択用のデータ構造
    struct ImportItem: Identifiable {
        let id = UUID()
        let preset: SubscriptionPreset
        var isSelected: Bool
        var selectedPlan: SubscriptionPlan
    }
    
    @State private var importItems: [ImportItem] = []
    @State private var isImporting = false
    @State private var showingSuccessToast = false
    @State private var successCount = 0
    
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }
    
    // MARK: - Initializer
    
    init() {
        // Apple Storeでよく決済される代表的なサービスをプリセットから抽出して初期値にする
        let appleRelatedNames = ["iCloud+", "Apple Music", "Apple TV+", "Apple Arcade", "YouTube Premium", "Netflix", "Disney+"]
        let foundPresets = SubscriptionPreset.defaultPresets.filter { preset in
            appleRelatedNames.contains(preset.name)
        }
        
        let items = foundPresets.compactMap { preset -> ImportItem? in
            guard let firstPlan = preset.plans.first else { return nil }
            // iCloud+は200GB、YouTube Premiumは個人、Apple Musicは個人プランをデフォルト選択にする
            let defaultPlan = preset.plans.first { plan in
                plan.name.contains("200GB") || plan.name.contains("個人") || plan.name.contains("スタンダード")
            } ?? firstPlan
            
            return ImportItem(preset: preset, isSelected: false, selectedPlan: defaultPlan)
        }
        
        _importItems = State(initialValue: items)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ガイドヘッダー
                    guideHeaderSection
                    
                    // ステップ1: Apple ID設定画面への誘導
                    stepOneSection
                    
                    // ステップ2: インポート選択リスト
                    stepTwoSection
                    
                    // インポート実行ボタン
                    importActionButton
                }
                .padding()
            }
            .navigationTitle("Apple ID サブスク連携")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background(Color(.systemGroupedBackground).opacity(0.6))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            
            // 豪華なトースト表示
            if showingSuccessToast {
                successToastOverlay
            }
        }
    }
    
    // MARK: - サブビュー
    
    private var guideHeaderSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(currentTheme.color.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "applelogo")
                    .font(.title)
                    .foregroundStyle(currentTheme.color)
            }
            
            Text("Apple ID 連携アシスタント")
                .font(.title3)
                .fontWeight(.black)
            
            Text("iOSのシステム制限により、他アプリのサブスクを直接自動インポートすることはできません。そのため、本アシスタントで簡単かつスムーズに登録を行いましょう！")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
    
    private var stepOneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("1")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(currentTheme.color))
                
                Text("Apple IDの現在の購読状況を確認")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Text("以下のボタンをタップすると、Apple Storeの「サブスクリプション」管理画面へ直接遷移します。現在自分が登録しているプランと金額を一度ご確認ください。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button {
                openAppleSubscriptions()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square.fill")
                    Text("Apple ID サブスク管理を開く")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.black, Color(.systemGray6).opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var stepTwoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text("2")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(currentTheme.color))
                
                Text("契約中のサブスクを選択してインポート")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Text("確認した登録サービスをチェックし、プランを選択してください。コテサクへ一括で登録されます。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach($importItems) { $item in
                    HStack(spacing: 12) {
                        // チェックボックス
                        Toggle(isOn: $item.isSelected) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(item.preset.category.color.opacity(0.12))
                                        .frame(width: 38, height: 38)
                                    
                                    Image(systemName: item.preset.iconName)
                                        .font(.subheadline)
                                        .foregroundStyle(item.preset.category.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.preset.name)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    Text(CurrencyHelper.formatted(amount: item.selectedPlan.amount))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .toggleStyle(CheckboxToggleStyle(activeColor: currentTheme.color))
                        
                        Spacer()
                        
                        // プランピッカー（選択中のみ表示）
                        if item.isSelected {
                            Picker("プラン", selection: $item.selectedPlan) {
                                ForEach(item.preset.plans) { plan in
                                    Text("\(plan.name) (\(CurrencyHelper.formatted(amount: plan.amount)))")
                                        .tag(plan)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .tint(currentTheme.color)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if item.id != importItems.last?.id {
                        Divider()
                            .background(Color.primary.opacity(0.06))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var importActionButton: some View {
        let selectedCount = importItems.filter { $0.isSelected }.count
        
        return Button {
            Task {
                await executeImport()
            }
        } label: {
            HStack {
                if isImporting {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 8)
                } else {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                }
                Text(selectedCount > 0 ? "\(selectedCount)件のサブスクを一括インポート" : "インポートするサービスを選択してください")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: selectedCount > 0 ? currentTheme.gradientColors : [.gray, .gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: selectedCount > 0 ? currentTheme.color.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(selectedCount == 0 || isImporting)
    }
    
    private var successToastOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("\(successCount)件のサブスクを一括インポートしました！")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
            )
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - アクションメソッド
    
    private func openAppleSubscriptions() {
        let urlStrings = [
            "itms-apps://apps.apple.com/account/subscriptions",
            "https://apps.apple.com/account/subscriptions"
        ]
        
        for urlStr in urlStrings {
            if let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                break
            }
        }
    }
    
    private func executeImport() async {
        isImporting = true
        let selectedList = importItems.filter { $0.isSelected }
        successCount = selectedList.count
        
        // 1. SwiftDataコンテキストへの一括インサート (MainActor上で高速実行)
        var createdSubscriptions: [Subscription] = []
        for item in selectedList {
            let subscription = Subscription(
                name: "\(item.preset.name) (\(item.selectedPlan.name))",
                amount: item.selectedPlan.amount,
                billingCycle: item.selectedPlan.billingCycle,
                category: item.preset.category,
                startDate: Date(), // 本日から契約開始
                iconName: item.preset.iconName
            )
            
            subscription.updateNextPaymentDate()
            modelContext.insert(subscription)
            createdSubscriptions.append(subscription)
        }
        
        try? modelContext.save()
        
        // 2. カレンダー登録および通知スケジュール処理の並列高速処理 (TaskGroupの適用)
        await withTaskGroup(of: Void.self) { group in
            for subscription in createdSubscriptions {
                group.addTask {
                    // 請求日前の通知スケジュール
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
                    
                    // カレンダー自動連携
                    if UserDefaults.standard.bool(forKey: "calendarSyncEnabled") {
                        await CalendarService.syncSubscription(subscription)
                    }
                }
            }
        }
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        isImporting = false
        
        withAnimation(.spring()) {
            showingSuccessToast = true
        }
        
        // 2秒後に画面を閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingSuccessToast = false
            }
            dismiss()
        }
    }
}

// MARK: - カスタムToggleStyle (チェックボックス)

struct CheckboxToggleStyle: ToggleStyle {
    let activeColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? activeColor : .secondary)
                .font(.title3)
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
            
            configuration.label
        }
    }
}
