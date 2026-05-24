//
//  DashboardView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// ダッシュボード画面。
/// 月額合計・年額合計のサマリーカードと、直近の請求予定リストを表示する。
struct DashboardView: View {

    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true },
        sort: \Subscription.nextPaymentDate
    ) private var subscriptions: [Subscription]

    @Query(
        sort: \ReductionHistory.cancelledDate,
        order: .reverse
    ) private var reductionHistories: [ReductionHistory]

    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = DashboardViewModel()
    @State private var showingReviewWizard = false
    @State private var showingAddView = false
    @State private var showingAppleImporter = false
    @State private var showingCalendarImporter = false
    
    // 削減目標設定用
    @AppStorage("monthlySavingsGoal") private var monthlySavingsGoal = 0
    @State private var showingGoalEditSheet = false
    @State private var tempGoalText = ""
    
    // 追加: グラフの表示モード
    @State private var chartMode: DashboardChartMode = .byService
    
    // コスパ診断からの直接編集用
    @State private var selectedSubscriptionForEdit: Subscription? = nil

    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if subscriptions.isEmpty && reductionHistories.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 20) {
                        reducedSummaryCard
                        
                        reviewButton
                        summaryCards
                        DistributionChartView(
                            mode: $chartMode,
                            categoryData: viewModel.monthlyAmountByCategory(subscriptions),
                            serviceData: viewModel.monthlyAmountByService(subscriptions)
                        )
                        
                        let diagnosisIssues = viewModel.diagnoseCostPerformance(subscriptions)
                        if !diagnosisIssues.isEmpty {
                            costPerformanceDiagnosisSection(issues: diagnosisIssues)
                        }
                        
                        upcomingSection
                    }
                    .padding()
                }
            }
            .navigationTitle("ダッシュボード")
            .task {
                viewModel.migrateLegacyInactiveSubscriptions(using: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddView = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingReviewWizard) {
                ReviewWizardView(activeSubscriptions: subscriptions)
            }
            .sheet(isPresented: $showingAddView) {
                NavigationStack {
                    AddSubscriptionView(isModal: true)
                }
            }
            .sheet(isPresented: $showingGoalEditSheet) {
                goalEditSheetView
            }
            .sheet(item: $selectedSubscriptionForEdit) { subscription in
                EditSubscriptionView(subscription: subscription)
            }
            .sheet(isPresented: $showingAppleImporter) {
                NavigationStack {
                    AppleSubscriptionImporterView()
                }
            }
            .sheet(isPresented: $showingCalendarImporter) {
                NavigationStack {
                    CalendarImportView()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowReviewWizard"))) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingReviewWizard = true
                }
            }
        }
    }
    
    // MARK: - 空状態（Empty State）
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ウェルカムヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(currentTheme.color)
                        .padding(.top, 32)
                    
                    Text("さあ、未来を変えましょう！")
                        .font(.title2)
                        .fontWeight(.black)
                    
                    Text("最初のサブスクを登録して、\n無駄な出費の見える化をスタートしましょう。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // メインの登録ボタン
                Button {
                    showingAddView = true
                } label: {
                    Text("最初のサブスクを登録する")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(currentTheme.color)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: currentTheme.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // 迷ったときのアドバイスセクション
                VStack(alignment: .leading, spacing: 16) {
                    Label("💡 何を登録すればいいか迷ったら？", systemImage: "lightbulb.max.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.bottom, 4)
                    
                    Text("Amazon Prime、Netflix、Spotify、ジム、iCloudなど、毎月自動で支払っているものを思い出してみましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                    
                    // インポートアクションボタン群
                    VStack(spacing: 12) {
                        Button {
                            showingAppleImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                    .frame(width: 24)
                                Text("Apple IDから自動連携する")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            showingCalendarImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .frame(width: 24)
                                    .foregroundStyle(.red)
                                Text("カレンダーから自動連携する")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // スクショのアドバイス
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("スクショを見ながら登録")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("クレジットカードの明細や、設定アプリの『サブスクリプション』画面のスクショを撮って、見ながら入力するのもおすすめです。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - 削減累計額カード
    
    private var reducedSummaryCard: some View {
        VStack(spacing: 12) {
            // 上部：実績表示と実績画面への遷移リンク
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                        Text("固定費削減の積み上げ実績")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white.opacity(0.9))

                    let totalYearlyReduced = viewModel.totalReducedYearlyAmount(reductionHistories)
                    let totalMonthlyReduced = viewModel.totalReducedMonthlyAmount(reductionHistories)

                    Text(CurrencyHelper.formatted(amount: totalYearlyReduced))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        + Text(" /年 節約中")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.9))

                    Text("月額換算: \(CurrencyHelper.formatted(amount: totalMonthlyReduced)) の削減")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.95))
                }

                Spacer()

                // 削減件数バッジ 兼 削減履歴リンク
                NavigationLink(destination: PastSubscriptionsView()) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("\(reductionHistories.count)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("削減履歴")
                            .font(.system(size: 9))
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            // 下部：目標設定と進捗ゲージ
            let totalMonthlyReduced = viewModel.totalReducedMonthlyAmount(reductionHistories)
            let progress = monthlySavingsGoal > 0 ? (Double(truncating: totalMonthlyReduced as NSDecimalNumber) / Double(monthlySavingsGoal)) : 0.0
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.goalMotivationMessage(progress: progress, hasGoal: monthlySavingsGoal > 0))
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        tempGoalText = monthlySavingsGoal > 0 ? "\(monthlySavingsGoal)" : ""
                        showingGoalEditSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                            Text(monthlySavingsGoal > 0 ? "目標変更" : "目標設定")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if monthlySavingsGoal > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("月間目標 \(CurrencyHelper.formatted(amount: Decimal(monthlySavingsGoal)))")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.85))
                            Spacer()
                            Text("\(Int(min(progress, 9.99) * 100))% 達成")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(progress >= 1.0 ? Color.yellow : Color.white)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(progress >= 1.0 ? Color.yellow : Color.white)
                                    .frame(width: geo.size.width * CGFloat(min(progress, 1.0)), height: 6)
                                    .shadow(color: progress >= 1.0 ? .yellow : .white, radius: 3)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: currentTheme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: currentTheme.color.opacity(0.3), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - 見直しボタン

    private var reviewButton: some View {
        Button {
            showingReviewWizard = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("サブスクを見直す")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - サマリーカード

    /// 月額・年額合計を表示するカードエリア
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCardView(
                title: "月額合計",
                amount: viewModel.totalMonthlyAmount(subscriptions),
                iconName: "calendar",
                color: .blue
            )
            SummaryCardView(
                title: "年額合計",
                amount: viewModel.totalYearlyAmount(subscriptions),
                iconName: "calendar.badge.clock",
                color: .purple
            )
        }
    }

    // MARK: - 直近の請求予定

    /// 直近の請求予定セクション
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近の請求予定")
                .font(.headline)

            let upcoming = viewModel.upcomingSubscriptions(subscriptions)

            if upcoming.isEmpty {
                Text("予定されている請求はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(upcoming) { subscription in
                    UpcomingRowView(subscription: subscription)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    // MARK: - 新機能用のビュー

    /// 目標設定編集用シートビュー
    private var goalEditSheetView: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                        TextField("目標削減額を入力", text: $tempGoalText)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .font(.title2)
                    }
                } header: {
                    Text("月間削減目標金額")
                } footer: {
                    Text("不要なサブスクや固定費を見直して、毎月いくら削減したいかの合計目標金額を設定します。")
                }
            }
            .navigationTitle("目標設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingGoalEditSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let goal = Int(tempGoalText), goal >= 0 {
                            monthlySavingsGoal = goal
                        } else if tempGoalText.isEmpty {
                            monthlySavingsGoal = 0
                        }
                        showingGoalEditSheet = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.32)])
    }

    /// コスパ診断警告セクション
    private func costPerformanceDiagnosisSection(issues: [DashboardViewModel.CostPerformanceIssue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("スマートコスパ診断", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(issues.count)件の警告")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                // カテゴリアイコン
                                Image(systemName: issue.subscription.iconName)
                                    .font(.body)
                                    .padding(8)
                                    .background(issue.subscription.category.color.opacity(0.2))
                                    .foregroundStyle(issue.subscription.category.color)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(issue.subscription.name)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    
                                    Text(CurrencyHelper.formatted(amount: issue.subscription.monthlyAmount) + "/月")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // 警告ステータス
                                Text(issue.isCritical ? "解約推奨" : "要検討")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(issue.isCritical ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundStyle(issue.isCritical ? Color.red : Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            
                            // 満足度と利用頻度
                            HStack {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption2)
                                    Text("\(issue.subscription.satisfaction)")
                                }
                                .font(.caption2)
                                .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text("月利用: \(issue.subscription.monthlyUsageCount)回")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 2)
                            
                            Divider()
                                .background(Color.primary.opacity(0.15))
                            
                            // アドバイス
                            Text(issue.advice)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .frame(height: 48, alignment: .topLeading)
                                .multilineTextAlignment(.leading)
                            
                            // ショートカットアクション
                            HStack(spacing: 8) {
                                Button {
                                    selectedSubscriptionForEdit = issue.subscription
                                } label: {
                                    Text("見直す・編集")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .frame(width: 240)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(issue.isCritical ? Color.red.opacity(0.25) : Color.orange.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
