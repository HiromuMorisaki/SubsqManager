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

    // 月1見直しリマインダー連携用
    @AppStorage("monthlyReviewNotificationEnabled") private var monthlyReviewNotificationEnabled = false
    @AppStorage("monthlyReviewDay") private var monthlyReviewDay = 25
    @AppStorage("monthlyReviewHour") private var monthlyReviewHour = 9
    @AppStorage("monthlyReviewMinute") private var monthlyReviewMinute = 0
    @AppStorage("monthlyReviewCalendarEnabled") private var monthlyReviewCalendarEnabled = false
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false

    /// 人気のサブスクを1タップで直接登録・保存する
    private func addPresetDirectly(name: String, amount: Decimal, category: Category, iconName: String) {
        // Haptic Feedback
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif

        let newSub = Subscription(
            name: name,
            amount: amount,
            billingCycle: .monthly,
            category: category,
            startDate: Date(),
            iconName: iconName
        )
        newSub.satisfaction = 4
        newSub.usageFrequency = .daily
        newSub.paymentMethod = .creditCard
        
        modelContext.insert(newSub)
        try? modelContext.save()

        // 共有 AppGroup ウィジェットデータの同期
        WidgetDataShareHelper.updateSharedSavingsAmount(using: modelContext)

        // カレンダー同期（自動同期が有効なら）
        if calendarSyncEnabled {
            Task {
                await CalendarService.syncAllSubscriptions(subscriptions: subscriptions)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if subscriptions.isEmpty && reductionHistories.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 20) {
                        Picker("用途", selection: $viewModel.expenseFilter) {
                            ForEach(ExpenseFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        let filteredSubs = viewModel.filteredSubscriptions(subscriptions)
                        
                        // 月1コテサク見直しデーが未登録の場合のみ、美しきインラインバナーを表示して動機付けを強力にする
                        if !monthlyReviewNotificationEnabled {
                            monthlyReviewNudgeBanner
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        reducedSummaryCard
                        
                        reviewButton
                        
                        actualBillingCard(filteredSubs)
                        
                        HStack(spacing: 12) {
                            SummaryCardView(
                                title: "月額換算",
                                amount: viewModel.totalMonthlyAmount(filteredSubs),
                                iconName: "calendar",
                                color: .blue
                            )
                            SummaryCardView(
                                title: "年額換算",
                                amount: viewModel.totalYearlyAmount(filteredSubs),
                                iconName: "calendar.badge.clock",
                                color: .purple
                            )
                        }
                        
                        DistributionChartView(
                            mode: $chartMode,
                            categoryData: viewModel.monthlyAmountByCategory(filteredSubs),
                            serviceData: viewModel.monthlyAmountByService(filteredSubs)
                        )
                        
                        let diagnosisIssues = viewModel.diagnoseCostPerformance(filteredSubs)
                        if !diagnosisIssues.isEmpty {
                            costPerformanceDiagnosisSection(issues: diagnosisIssues)
                        }
                        
                        upcomingSection(filteredSubs)
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
    
    // MARK: - インライン月1コテサク見直し登録バナー (未登録ユーザー向け)
    
    private var monthlyReviewNudgeBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // 美しい光彩を放つテーマカラーのアイコン
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: currentTheme.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .shadow(color: currentTheme.color.opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("月1回のコテサク見直しを始めませんか？")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Text("節約効果 💡")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LinearGradient(colors: currentTheme.gradientColors, startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                    
                    Text("給料日前後の「毎月25日」に見直し診断を行うだけで、年間平均3〜5万円の無駄な“払い損”を防止できます。忘れがちなサブスク管理を完全に自動化しましょう。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    // 1タップ登録処理 (Haptic Feedback)
                    #if os(iOS)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    #endif
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        monthlyReviewDay = 25
                        monthlyReviewNotificationEnabled = true
                        monthlyReviewCalendarEnabled = true
                    }
                    
                    Task {
                        let authorized = await NotificationService.requestAuthorization()
                        if authorized {
                            await NotificationService.scheduleMonthlyReviewReminder(day: 25, hour: 9, minute: 0)
                            
                            if calendarSyncEnabled {
                                let calAuthorized = await CalendarService.requestAuthorization()
                                if calAuthorized {
                                    await CalendarService.syncMonthlyReviewEvents(day: 25)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("給料日の25日にリマインドを設定 (1タップ)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 14)
                    .background(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    // 設定画面へ遷移する通知を投稿
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettingsTab"), object: nil)
                } label: {
                    Text("別の日を設定")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 14)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal)
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
                
                // 1タップ人気サブスク即時登録セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("【人気】よく使うサービスを1タップで追加")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    
                    let popularPresets = [
                        ("Netflix", Decimal(990), Category.entertainment, "tv"),
                        ("Spotify", Decimal(980), Category.music, "music.note"),
                        ("Amazon Prime", Decimal(600), Category.lifestyle, "creditcard"),
                        ("YouTube Premium", Decimal(1280), Category.entertainment, "film"),
                        ("iCloud+", Decimal(130), Category.cloud, "cloud"),
                        ("Apple Music", Decimal(1080), Category.music, "music.note")
                    ]
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(popularPresets, id: \.0) { preset in
                            Button {
                                addPresetDirectly(
                                    name: preset.0,
                                    amount: preset.1,
                                    category: preset.2,
                                    iconName: preset.3
                                )
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: preset.3)
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.color)
                                        .frame(width: 24, height: 24)
                                        .background(currentTheme.color.opacity(0.1))
                                        .cornerRadius(6)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.0)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text(CurrencyHelper.formatted(amount: preset.1) + "/月")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(currentTheme.color)
                                        .font(.subheadline)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 4)
                
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
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(CurrencyHelper.formatted(amount: totalMonthlyReduced))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/月 節約中")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text("年間換算: 今後1年間で約 \(CurrencyHelper.formatted(amount: totalYearlyReduced)) の節約想定")
                        .font(.caption)
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

    // MARK: - 今月の実際の請求額カード
    
    private func actualBillingCard(_ filteredSubs: [Subscription]) -> some View {
        let actualAmount = viewModel.actualBillingAmountThisMonth(filteredSubs)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("今月実際に支払う総額", systemImage: "yensign.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("実際のキャッシュフロー")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(CurrencyHelper.formatted(amount: actualAmount))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("今月")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }
            
            Text("※ 月額・年額などの更新日をもとに、今月中に引き落とされる金額の合計です。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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

    // MARK: - 直近の請求予定

    /// 直近の請求予定セクション
    private func upcomingSection(_ filteredSubs: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近の請求予定")
                .font(.headline)

            let upcoming = viewModel.upcomingSubscriptions(filteredSubs)

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
        let criticalCount = issues.filter { $0.type == .critical }.count
        let warningCount = issues.filter { $0.type == .warning }.count
        let excellenceCount = issues.filter { $0.type == .excellence }.count
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("スマートコスパ診断", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    if criticalCount > 0 {
                        Text("要注意: \(criticalCount)件")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    if warningCount > 0 {
                        Text("要検討: \(warningCount)件")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    if excellenceCount > 0 {
                        Text("優秀: \(excellenceCount)件")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(issues) { issue in
                        CostPerformanceCardView(
                            issue: issue,
                            selectedSubscriptionForEdit: $selectedSubscriptionForEdit
                        )
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

/// スマートコスパ診断の各サブスクリプションカードUI
struct CostPerformanceCardView: View {
    let issue: DashboardViewModel.CostPerformanceIssue
    @Binding var selectedSubscriptionForEdit: Subscription?
    
    var body: some View {
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
                
                // 警告・優秀ステータスバッジ
                statusBadge
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
                    Text(issue.type == .excellence ? "詳細・編集" : "見直す・編集")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(issue.type == .excellence ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.1))
                        .foregroundStyle(issue.type == .excellence ? Color.green : Color.accentColor)
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
                .stroke(strokeColor, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - プライベートヘルパー
    
    private var statusBadge: some View {
        let badgeText: String
        let badgeBgColor: Color
        let badgeFgColor: Color
        
        switch issue.type {
        case .critical:
            badgeText = "解約推奨"
            badgeBgColor = Color.red.opacity(0.15)
            badgeFgColor = Color.red
        case .warning:
            badgeText = "要検討"
            badgeBgColor = Color.orange.opacity(0.15)
            badgeFgColor = Color.orange
        case .excellence:
            badgeText = "コスパ優秀"
            badgeBgColor = Color.green.opacity(0.15)
            badgeFgColor = Color.green
        }
        
        return Text(badgeText)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeBgColor)
            .foregroundStyle(badgeFgColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var strokeColor: Color {
        switch issue.type {
        case .critical:
            return Color.red.opacity(0.25)
        case .warning:
            return Color.orange.opacity(0.25)
        case .excellence:
            return Color.green.opacity(0.25)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
