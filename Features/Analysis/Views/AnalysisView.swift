//
//  AnalysisView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData
import Charts

/// 登録されているサブスクリプションデータを Swift Charts を使ってグラフ化・分析する画面。
/// 【Phase 9】家計分析の高度化と固定費予測シミュレーションの導入により、大幅にデザインと機能を強化。
struct AnalysisView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true }
    ) private var subscriptions: [Subscription]
    
    @State private var viewModel = AnalysisViewModel()
    @State private var showingAddView = false
    
    // サブセグメント切り替え用
    @State private var selectedSubTab = 0 // 0: 家計分析, 1: 固定費予測
    @Namespace private var tabAnimationNamespace
    
    // シミュレータトグル状態
    @State private var excludeSatisfactionTwoOrLess = false
    @State private var excludeUsageOneOrLess = false
    @State private var excludeTrials = false
    
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    let activeSubs = subscriptions.filter { !$0.isExpired }
                    
                    if activeSubs.isEmpty {
                        emptyStateSection
                    } else {
                        // 1. カスタムタブコントロール
                        customSegmentedControl
                        
                        if selectedSubTab == 0 {
                            // 2. 家計分析コンテンツ
                            analysisTabContent(activeSubs: activeSubs)
                        } else {
                            // 3. 固定費予測・シミュレーションコンテンツ
                            simulationTabContent(activeSubs: activeSubs)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("分析・シミュレーション")
            .background(Color(.systemGroupedBackground).opacity(0.6))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddView = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                NavigationStack {
                    AddSubscriptionView(isModal: true)
                }
            }
        }
    }
    
    // MARK: - 空状態の表示
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "分析データがありません",
                systemImage: "chart.bar.xaxis",
                description: Text("サブスクリプションを追加すると、ここに支出の割合や削減シミュレーション結果が表示されます。")
            )
            
            Button {
                showingAddView = true
            } label: {
                Text("最初のサブスクを登録する")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(
                        LinearGradient(
                            colors: currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: currentTheme.color.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - カスタムセグメントコントロール (CapsuleStyle MatchedGeometry)
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedSubTab = 0
                }
            } label: {
                Text("家計分析")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedSubTab == 0 ? .white : .secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedSubTab == 0 {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: currentTheme.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .matchedGeometryEffect(id: "activeTab", in: tabAnimationNamespace)
                        }
                    }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedSubTab = 1
                }
            } label: {
                Text("固定費予測")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedSubTab == 1 ? .white : .secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selectedSubTab == 1 {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: currentTheme.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .matchedGeometryEffect(id: "activeTab", in: tabAnimationNamespace)
                        }
                    }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    // MARK: - 【家計分析】コンテンツ
    private func analysisTabContent(activeSubs: [Subscription]) -> some View {
        VStack(spacing: 24) {
            // 1. サマリー指標カード
            overallSummaryCard(activeSubs: activeSubs)
            
            // 2. 満足度別支出グラフ
            satisfactionBreakdownChart(activeSubs: activeSubs)
            
            // 3. カテゴリ別支出割合 (円グラフ & リスト)
            categoryBreakdownSection(activeSubs: activeSubs)
        }
    }
    
    // MARK: - 【固定費予測】コンテンツ
    private func simulationTabContent(activeSubs: [Subscription]) -> some View {
        VStack(spacing: 24) {
            // 1. シミュレーション条件コントローラー
            simulationControllerCard
            
            // 2. Before/After 削減予測結果カード
            simulationResultCard(activeSubs: activeSubs)
            
            // 3. 今後の支出予測推移グラフ (Before/After)
            expenditureTrendComparisonChart(activeSubs: activeSubs)
        }
    }
    
    // MARK: - 家計分析: サマリーカード
    private func overallSummaryCard(activeSubs: [Subscription]) -> some View {
        let totalMonthly = activeSubs.reduce(Decimal.zero) { $0 + $1.ownShareMonthlyAmount }
        let totalYearly = activeSubs.reduce(Decimal.zero) { $0 + $1.ownShareYearlyAmount }
        let avgSatisfaction = viewModel.averageSatisfaction(from: activeSubs)
        let wastageIdx = viewModel.wastageIndex(from: activeSubs)
        let wastageAmt = viewModel.wastageAmount(from: activeSubs)
        
        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("月額総支出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    Text(CurrencyHelper.formatted(amount: totalMonthly))
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("年額総支出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    Text(CurrencyHelper.formatted(amount: totalYearly))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // 平均満足度の星マーク
            HStack {
                Label("平均満足度", systemImage: "face.smiling.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                starRatingView(rating: avgSatisfaction)
                
                Text(String(format: "%.1f", avgSatisfaction))
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Divider()
            
            // 無駄遣い指数 (Wastage Index) 進捗ゲージ
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("削減ポテンシャル（無駄遣い指数）", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(wastageIdx > 0.3 ? .red : .orange)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", wastageIdx * 100))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(wastageIdx > 0.3 ? .red : .orange)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: wastageIdx > 0.3 ? [.orange, .red] : [currentTheme.color, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(wastageIdx, 1.0)), height: 8)
                            .shadow(color: wastageIdx > 0.3 ? .red.opacity(0.3) : currentTheme.color.opacity(0.3), radius: 3)
                    }
                }
                .frame(height: 8)
                
                if wastageIdx > 0 {
                    Text("満足度が低い、または利用のないサブスクが月額 \(CurrencyHelper.formatted(amount: wastageAmt)) を占めています。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                } else {
                    Text("素晴らしい管理状態です！無駄な支出はありません。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 家計分析: 満足度別支出グラフ
    private func satisfactionBreakdownChart(activeSubs: [Subscription]) -> some View {
        let breakdown = viewModel.satisfactionBreakdown(from: activeSubs)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("満足度別の月額支出額")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Chart {
                ForEach(breakdown) { data in
                    BarMark(
                        x: .value("満足度", "★\(data.rating)"),
                        y: .value("金額", data.amount)
                    )
                    .foregroundStyle(
                        barGradientForSatisfaction(rating: data.rating)
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .padding(.vertical, 8)
            
            Text("※ 満足度★1〜2に分類されたサブスクは削減の最有力候補です。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    /// 満足度ごとに棒グラフのカラーグラデーションを設定する
    private func barGradientForSatisfaction(rating: Int) -> LinearGradient {
        switch rating {
        case 1, 2:
            return LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
        case 3:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [currentTheme.color, currentTheme.color.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        }
    }
    
    // MARK: - 家計分析: カテゴリ別支出割合 (円グラフ & 詳細リスト)
    private func categoryBreakdownSection(activeSubs: [Subscription]) -> some View {
        let breakdown = viewModel.categoryDetailedBreakdown(from: activeSubs)
        let totalAmount = breakdown.reduce(Decimal.zero) { $0 + $1.amount }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ別支出詳細")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if #available(iOS 17.0, macOS 14.0, *) {
                // 1. 円グラフ
                Chart {
                    ForEach(breakdown) { data in
                        SectorMark(
                            angle: .value("金額", data.amount),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("カテゴリ", data.category.displayName))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 180)
                .padding(.vertical, 8)
                
                Divider()
                
                // 2. リスト表示 (詳細内訳：満足度平均・件数付き)
                VStack(spacing: 12) {
                    ForEach(breakdown) { data in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(data.category.color)
                                .frame(width: 8, height: 8)
                            
                            Image(systemName: data.category.iconName)
                                .font(.caption)
                                .foregroundStyle(data.category.color)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(data.category.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    
                                    Text("\(data.subscriptionCount)件")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(Capsule())
                                }
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.system(size: 8))
                                    Text(String(format: "平均 ★%.1f", data.averageSatisfaction))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(CurrencyHelper.formatted(amount: data.amount))
                                    .font(.subheadline.monospacedDigit())
                                    .fontWeight(.bold)
                                
                                let percentage = totalAmount > 0 ? (NSDecimalNumber(decimal: data.amount).doubleValue / NSDecimalNumber(decimal: totalAmount).doubleValue * 100) : 0
                                Text(String(format: "%.1f%%", percentage))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if data.id != breakdown.last?.id {
                            Divider()
                                .background(Color.primary.opacity(0.06))
                        }
                    }
                }
            } else {
                Text("円グラフはiOS 17以降で利用可能です。")
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 固定費予測: シミュレーターコントローラー
    private var simulationControllerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("削減シミュレーター", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(currentTheme.color)
            
            Text("条件を切り替えて、将来の支出がどう削減されるかを瞬時に検証・シミュレーションできます。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 14) {
                // 条件1
                Toggle(isOn: $excludeSatisfactionTwoOrLess) {
                    HStack(spacing: 12) {
                        Image(systemName: "star.bubble.fill")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("低満足度の削減")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("満足度 ★2以下のサブスクをすべて解約")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(currentTheme.color)
                
                Divider()
                    .background(Color.primary.opacity(0.06))
                
                // 条件2
                Toggle(isOn: $excludeUsageOneOrLess) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ほぼ使っていないサブスクの削減")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("月間利用回数が1回以下のサブスクをすべて解約")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(currentTheme.color)
                
                Divider()
                    .background(Color.primary.opacity(0.06))
                
                // 条件3
                Toggle(isOn: $excludeTrials) {
                    HStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("無料トライアルの削減")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("本契約に移行せず、期間内にすべて解約")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(currentTheme.color)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 固定費予測: シミュレーション結果Before/After & 1/3/5年累積カード
    private func simulationResultCard(activeSubs: [Subscription]) -> some View {
        let (monthlySavings, yearlySavings) = viewModel.calculateSimulationSavings(
            from: activeSubs,
            excludeSatisfactionTwoOrLess: excludeSatisfactionTwoOrLess,
            excludeUsageOneOrLess: excludeUsageOneOrLess,
            excludeTrials: excludeTrials
        )
        
        let totalYearly = activeSubs.reduce(Decimal.zero) { $0 + $1.ownShareYearlyAmount }
        let afterYearly = totalYearly - yearlySavings
        let savingsPercent = totalYearly > 0 ? (NSDecimalNumber(decimal: yearlySavings).doubleValue / NSDecimalNumber(decimal: totalYearly).doubleValue * 100) : 0.0
        
        return VStack(spacing: 16) {
            VStack(alignment: .center, spacing: 8) {
                Text("年間削減効果（削減ポテンシャル）")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fontWeight(.bold)
                
                Text(CurrencyHelper.formatted(amount: yearlySavings))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(String(format: "%.1f%% 削減", savingsPercent))
                        .font(.footnote)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Text("月額換算: \(CurrencyHelper.formatted(amount: monthlySavings))")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: yearlySavings > 0 ? currentTheme.gradientColors : [Color.gray.opacity(0.6), Color.gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: yearlySavings > 0 ? currentTheme.color.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
            
            // 1年後、3年後、5年後の累積節約予想
            VStack(alignment: .leading, spacing: 12) {
                Text("未来の累積節約額（積み上げ予測）")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    // 1年後
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1年後")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text("+\(CurrencyHelper.formatted(amount: yearlySavings * 1))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(yearlySavings > 0 ? currentTheme.color : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // 3年後
                    VStack(alignment: .leading, spacing: 6) {
                        Text("3年後")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text("+\(CurrencyHelper.formatted(amount: yearlySavings * 3))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(yearlySavings > 0 ? .orange : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // 5年後
                    VStack(alignment: .leading, spacing: 6) {
                        Text("5年後")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .fontWeight(.bold)
                        Text("+\(CurrencyHelper.formatted(amount: yearlySavings * 5))")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(yearlySavings > 0 ? .yellow : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(yearlySavings > 0 ? Color.yellow.opacity(0.3) : .clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 固定費予測: 今後の支出予測推移グラフ (Before/After 2系列重ね合わせ)
    private func expenditureTrendComparisonChart(activeSubs: [Subscription]) -> some View {
        let trendData = viewModel.monthlyTrendComparison(
            from: activeSubs,
            excludeSatisfactionTwoOrLess: excludeSatisfactionTwoOrLess,
            excludeUsageOneOrLess: excludeUsageOneOrLess,
            excludeTrials: excludeTrials
        )
        
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今後12ヶ月の支出推移予測")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("終了予定日やトライアル終了による月別変動も正確に考慮")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // 凡例表示
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "line.diagonal")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text("現行予測 (Before)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "line.diagonal")
                        .font(.caption2)
                        .foregroundStyle(currentTheme.color)
                    Text("シミュレーション後 (After)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                ForEach(trendData) { data in
                    // Before (ダッシュグレー線)
                    LineMark(
                        x: .value("月", data.month, unit: .month),
                        y: .value("Before金額", data.beforeAmount)
                    )
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4]))
                    .interpolationMethod(.monotone)
                    
                    // After (テーマのネオンカラー太線)
                    LineMark(
                        x: .value("月", data.month, unit: .month),
                        y: .value("After金額", data.afterAmount)
                    )
                    .foregroundStyle(currentTheme.color)
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    
                    // After用のグラデーション塗布
                    AreaMark(
                        x: .value("月", data.month, unit: .month),
                        y: .value("After金額", data.afterAmount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [currentTheme.color.opacity(0.2), currentTheme.color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 1)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            let month = Calendar.current.component(.month, from: date)
                            Text("\(month)月")
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 星マーク評価ビューヘルパー
    private func starRatingView(rating: Double) -> some View {
        HStack(spacing: 2) {
            let intPart = Int(rating)
            let fraction = rating - Double(intPart)
            ForEach(1...5, id: \.self) { index in
                if index <= intPart {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                } else if index == intPart + 1 && fraction >= 0.5 {
                    Image(systemName: "star.leadinghalf.filled")
                        .foregroundStyle(.yellow)
                } else {
                    Image(systemName: "star")
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
        }
        .font(.caption)
    }
}

#Preview {
    let container = try! ModelContainer(for: Subscription.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // サンプルデータをインサート
    let samples = [
        Subscription(name: "Netflix", amount: 1490, billingCycle: .monthly, category: .entertainment, startDate: Date(), satisfaction: 4, monthlyUsageCount: 15),
        Subscription(name: "Adobe CC", amount: 6480, billingCycle: .monthly, category: .work, startDate: Date(), satisfaction: 2, monthlyUsageCount: 1),
        Subscription(name: "Spotify Shared", amount: 980, billingCycle: .monthly, category: .music, startDate: Date(), satisfaction: 5, monthlyUsageCount: 30, isShared: true, ownSharePercentage: 0.5),
        Subscription(name: "Fitness", amount: 8800, billingCycle: .monthly, category: .healthcare, startDate: Date(), satisfaction: 3, monthlyUsageCount: 2)
    ]
    for sample in samples {
        container.mainContext.insert(sample)
    }
    
    return AnalysisView()
        .modelContainer(container)
}
