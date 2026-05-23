//
//  CalendarImportView.swift
//  SubsqManager
//
//  Created by AI on 2026/05/22.
//

import SwiftUI
import SwiftData
import EventKit

/// 外部カレンダー（TimeTree, Googleカレンダー等）からサブスク候補を検出し、インポートするView。
struct CalendarImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }
    
    /// カレンダー自動連携のON/OFFフラグ
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false
    
    // スキャン対象年月
    @State private var scanMonth = Date()
    @State private var candidates: [SubscriptionCandidate] = []
    
    // 選択された候補のIDリスト
    @State private var selectedCandidateIds = Set<UUID>()
    
    // ローディング・状態管理
    @State private var isScanning = false
    @State private var hasScanned = false
    
    // 候補編集用
    @State private var editingCandidate: SubscriptionCandidate? = nil
    
    // アラート用
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 上部：月の選択とスキャンボタン
                scanHeaderSection
                
                Divider()
                
                // メインコンテンツエリア
                if isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("カレンダーイベントをスキャン中...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if !hasScanned {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.down.on.square.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(currentTheme.color.opacity(0.6))
                        
                        Text("外部カレンダーからサブスクを検出")
                            .font(.headline)
                        
                        Text("TimeTreeやGoogleカレンダーなどの予定から、「Amazon」「Netflix」といったサブスク請求候補を自動でスキャンし、コテサクへ一括登録できます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            performScan()
                        } label: {
                            Text("スキャンを開始する")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: 240)
                                .background(
                                    LinearGradient(
                                        colors: currentTheme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: currentTheme.color.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else if candidates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("サブスク請求候補は見つかりませんでした")
                            .font(.headline)
                        
                        Text("選択した月内に、サブスク関連のキーワード（サブスク、支払、引き落とし、会費など）を含むカレンダーの予定がありません。別の月を選択してお試しください。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    // 候補リスト表示
                    candidatesListView
                }
                
                // 下部インポート実行エリア
                if hasScanned && !candidates.isEmpty {
                    importFooterView
                }
            }
            .navigationTitle("外部カレンダー連携")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingCandidate) { candidate in
                EditCandidateSheet(candidate: candidate) { updatedCandidate in
                    if let index = candidates.firstIndex(where: { $0.id == updatedCandidate.id }) {
                        candidates[index] = updatedCandidate
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if alertTitle == "カレンダーの権限不足" {
                    Button("キャンセル", role: .cancel) {}
                    #if os(iOS)
                    Button("設定を開く") {
                        if let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                    #endif
                } else {
                    Button("OK") {
                        if alertTitle == "インポート完了" {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - カレンダー選択 & スキャンヘッダー
    private var scanHeaderSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("対象月の選択:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Spacer()
                
                DatePicker("対象月", selection: $scanMonth, displayedComponents: [.date])
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            if hasScanned {
                Button {
                    performScan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("もう一度再スキャン")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(currentTheme.color)
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.secondarySystemBackground).opacity(0.4))
    }
    
    // MARK: - 候補リストView
    private var candidatesListView: some View {
        List {
            Section {
                ForEach(candidates) { candidate in
                    let isSelected = selectedCandidateIds.contains(candidate.id)
                    
                    HStack(spacing: 12) {
                        // 1. チェックボックス
                        Button {
                            if isSelected {
                                selectedCandidateIds.remove(candidate.id)
                            } else {
                                selectedCandidateIds.insert(candidate.id)
                            }
                        } label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(isSelected ? currentTheme.color : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 2. カテゴリアイコン
                        Image(systemName: candidate.category.iconName)
                            .font(.body)
                            .padding(8)
                            .background(candidate.category.color.opacity(0.15))
                            .foregroundStyle(candidate.category.color)
                            .clipShape(Circle())
                        
                        // 3. 情報
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(candidate.name)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                
                                Button {
                                    editingCandidate = candidate
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            HStack(spacing: 6) {
                                Text(dateString(from: candidate.paymentDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(candidate.notes)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // 4. 金額
                        Text(CurrencyHelper.formatted(amount: candidate.amount))
                            .font(.body.monospacedDigit())
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                HStack {
                    Text("検出された候補 (\(candidates.count)件)")
                    Spacer()
                    Button("すべて選択") {
                        selectedCandidateIds = Set(candidates.map { $0.id })
                    }
                    .font(.caption)
                    .foregroundStyle(currentTheme.color)
                    
                    Text("|").foregroundStyle(.secondary.opacity(0.4))
                    
                    Button("解除") {
                        selectedCandidateIds.removeAll()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } footer: {
                Text("※カレンダーから自動抽出された金額やカテゴリが異なる場合、各項目の鉛筆マーク ✏️ からインポート前に手動修正できます。")
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - インポートフッター
    private var importFooterView: some View {
        VStack(spacing: 12) {
            let selectedCount = selectedCandidateIds.count
            let totalAmount = candidates
                .filter { selectedCandidateIds.contains($0.id) }
                .reduce(Decimal.zero) { $0 + $1.amount }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("選択中の件数: \(selectedCount) 件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("合計月額: \(CurrencyHelper.formatted(amount: totalAmount))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button {
                    performImport()
                } label: {
                    Text("選択したサブスクを登録")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: selectedCount > 0 ? currentTheme.gradientColors : [Color.gray.opacity(0.5), Color.gray.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: selectedCount > 0 ? currentTheme.color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                }
                .disabled(selectedCount == 0)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .border(Color.primary.opacity(0.06), width: 1)
        }
    }
    
    // MARK: - 制御アクション
    
    private func performScan() {
        Task {
            isScanning = true
            let authorized = await CalendarService.requestAuthorization()
            if authorized {
                let found = await CalendarService.detectSubscriptionCandidates(for: scanMonth)
                await MainActor.run {
                    self.candidates = found
                    self.selectedCandidateIds = Set(found.map { $0.id }) // 初期状態で全選択
                    self.hasScanned = true
                    self.isScanning = false
                }
            } else {
                await MainActor.run {
                    self.isScanning = false
                    self.alertTitle = "カレンダーの権限不足"
                    self.alertMessage = "外部カレンダーを参照するために、設定アプリからコテサクのカレンダー書き込み/アクセス権限を許可してください。"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func performImport() {
        let selected = candidates.filter { selectedCandidateIds.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        // 既存のすべてのサブスクリプションを取得
        let fetchDescriptor = FetchDescriptor<Subscription>()
        let existingSubs = (try? modelContext.fetch(fetchDescriptor)) ?? []
        
        var importedCount = 0
        var updatedCount = 0
        
        // カレンダー同期を行う必要があるサブスクリプションのリスト
        var subsToSync: [Subscription] = []
        
        for item in selected {
            // 同名のアクティブなサブスクが存在するかチェック（大文字小文字無視、トリム）
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if let existing = existingSubs.first(where: { 
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName.lowercased() && $0.isActive 
            }) {
                // すでに同名のアクティブなサブスクが存在する場合は更新する（重複追加は防ぐ）
                existing.amount = item.amount
                existing.nextPaymentDate = item.paymentDate
                existing.notes = item.notes
                existing.category = item.category
                existing.updateNextPaymentDate() // 支払予定日を未来へ更新
                
                subsToSync.append(existing)
                updatedCount += 1
            } else {
                // 新規登録
                let newSub = Subscription(
                    name: trimmedName,
                    amount: item.amount,
                    billingCycle: .monthly, // デフォルト月額
                    category: item.category,
                    startDate: item.paymentDate,
                    nextPaymentDate: item.paymentDate,
                    iconName: item.category.iconName,
                    notes: item.notes,
                    isActive: true
                )
                newSub.updateNextPaymentDate() // 支払予定日を未来へ更新
                modelContext.insert(newSub)
                
                subsToSync.append(newSub)
                importedCount += 1
            }
        }
        
        let isAlreadyEnabled = calendarSyncEnabled
        if !isAlreadyEnabled && CalendarService.isAuthorized {
            calendarSyncEnabled = true
        }
        
        do {
            try modelContext.save()
            
            // カレンダー同期を安全に一括で非同期実行（インポート確定後）
            if !subsToSync.isEmpty && calendarSyncEnabled && CalendarService.isAuthorized {
                Task { @MainActor in
                    await CalendarService.syncAllSubscriptions(subscriptions: subsToSync)
                }
            }
            
            alertTitle = "インポート完了"
            if isAlreadyEnabled {
                if updatedCount > 0 {
                    alertMessage = "新規で \(importedCount) 件登録し、既に登録のあった \(updatedCount) 件のサブスクリプションを最新状態に更新しました。\n\nカレンダー予定も自動で同期されました。"
                } else {
                    alertMessage = "\(importedCount)件のサブスクリプションを登録し、カレンダー予定も自動で同期されました。"
                }
            } else {
                if updatedCount > 0 {
                    alertMessage = "新規で \(importedCount) 件登録し、既に登録のあった \(updatedCount) 件のサブスクリプションを最新状態に更新しました。\n\n💡 カレンダー連携を自動でオンにし、カレンダー予定も同期しました。今後登録・更新するサブスクも自動で同期されます。"
                } else {
                    alertMessage = "\(importedCount)件のサブスクリプションを登録しました。\n\n💡 カレンダー連携を自動でオンにし、カレンダー予定も同期しました。今後登録・更新するサブスクも自動で同期されます。"
                }
            }
            showingAlert = true
        } catch {
            print("インポートデータ保存エラー: \(error)")
            alertTitle = "エラー"
            alertMessage = "サブスク候補の保存に失敗しました。"
            showingAlert = true
        }
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 候補個別編集用ハーフシート
struct EditCandidateSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var candidate: SubscriptionCandidate
    var onSave: (SubscriptionCandidate) -> Void
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var category = Category.other
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("サブスク名", text: $name)
                    
                    HStack {
                        Text("金額 (¥)")
                        Spacer()
                        TextField("金額", text: $amountString)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("分類") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(Category.allCases) { cat in
                            HStack {
                                Image(systemName: cat.iconName).foregroundStyle(cat.color)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("サブスク候補の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let amount = Decimal(string: amountString) ?? candidate.amount
                        var updated = candidate
                        updated.name = name
                        updated.amount = amount
                        updated.category = category
                        onSave(updated)
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = candidate.name
                amountString = "\(candidate.amount)"
                category = candidate.category
            }
        }
    }
}
