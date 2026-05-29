//
//  BulkImportPreviewSheet.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/28.
//

import SwiftUI
import SwiftData

/// 検出されたサブスクを一括で確認、インライン編集し、一括で登録を実行するプレビューハーフシートView。
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
