//
//  AnalysisView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData
import Charts

/// 登録されているサブスクリプションデータを Swift Charts を使ってグラフ化する画面。
struct AnalysisView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true }
    ) private var subscriptions: [Subscription]
    
    @State private var viewModel = AnalysisViewModel()
    @State private var showingAddView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if subscriptions.filter({ !$0.isTrial && !$0.isExpired }).isEmpty {
                        VStack(spacing: 16) {
                            ContentUnavailableView(
                                "データがありません",
                                systemImage: "chart.bar.xaxis",
                                description: Text("サブスクリプションを追加すると、ここにグラフが表示されます。")
                            )
                            
                            Button {
                                showingAddView = true
                            } label: {
                                Text("最初のサブスクを登録する")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: 300)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        trendChartSection
                        categoryChartSection
                    }
                }
                .padding()
            }
            .navigationTitle("分析")
            .background(Color.gray.opacity(0.05))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddView = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showingAddView) {
                AddSubscriptionView()
            }
        }
    }
    
    // MARK: - 推移グラフ (BarMark)
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今後の支出予測 (月額)")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Chart {
                ForEach(viewModel.monthlyTrend(from: subscriptions)) { data in
                    BarMark(
                        x: .value("月", data.month, unit: .month),
                        y: .value("金額", data.amount)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 1)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            let month = Calendar.current.component(.month, from: date)
                            Text("\(month)月")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
    }
    
    // MARK: - カテゴリ割合グラフ (SectorMark - iOS 17+)
    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ別支出割合")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if #available(iOS 17.0, macOS 14.0, *) {
                let breakdown = viewModel.categoryBreakdown(from: subscriptions)
                let totalAmount = breakdown.reduce(Decimal.zero) { $0 + $1.amount }
                
                VStack(spacing: 16) {
                    Chart {
                        ForEach(breakdown) { data in
                            SectorMark(
                                angle: .value("金額", data.amount),
                                innerRadius: .ratio(0.65),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("カテゴリ", data.category.displayName))
                            .annotation(position: .overlay) {
                                // 金額が大きければアイコンを表示するなど可能
                                Image(systemName: data.category.iconName)
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 220)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    VStack(spacing: 10) {
                        ForEach(breakdown) { data in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(data.category.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(data.category.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text(CurrencyHelper.formatted(amount: data.amount))
                                    .font(.subheadline.monospacedDigit())
                                    .fontWeight(.semibold)
                                
                                let percentage = totalAmount > 0 ? (NSDecimalNumber(decimal: data.amount).doubleValue / NSDecimalNumber(decimal: totalAmount).doubleValue * 100) : 0
                                Text(String(format: "%.1f%%", percentage))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            } else {
                Text("円グラフはiOS 17以降で利用可能です。")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
            }
        }
    }
}

#Preview {
    AnalysisView()
}
