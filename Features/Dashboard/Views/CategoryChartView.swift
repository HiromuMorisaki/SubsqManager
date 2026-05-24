//
//  DistributionChartView.swift
//  SubsqManager
//
//  Created by AI on 2026/05/25.
//

import SwiftUI
import Charts

/// 表示モードの定義
enum DashboardChartMode: String, CaseIterable, Identifiable {
    case byService = "サービス別"
    case byCategory = "カテゴリ別"
    var id: String { self.rawValue }
}

/// 汎用的な支出割合を示す円グラフView。
/// Swift Charts を使用して構築。
struct DistributionChartView: View {

    @Binding var mode: DashboardChartMode
    let categoryData: [(category: Category, amount: Decimal)]
    let serviceData: [(id: String, name: String, amount: Decimal, iconName: String, color: Color)]

    // サービス別グラフ用のビビッドなカラーパレット
    private let chartColors: [Color] = [
        .blue, .purple, .orange, .pink, .mint, .indigo, .cyan, .teal, .yellow, .red, .green
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mode == .byService ? "サービス別支出 (月額)" : "カテゴリ別支出 (月額)")
                    .font(.headline)
                Spacer()
                Picker("集計単位", selection: $mode) {
                    ForEach(DashboardChartMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            let isDataEmpty = mode == .byService ? serviceData.isEmpty : categoryData.isEmpty

            if isDataEmpty {
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                if mode == .byCategory {
                    chartByCategory
                    Divider().padding(.vertical, 4)
                    listByCategory
                } else {
                    chartByService
                    Divider().padding(.vertical, 4)
                    listByService
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Category Mode
    
    @ViewBuilder
    private var chartByCategory: some View {
        let totalAmount = NSDecimalNumber(decimal: categoryData.reduce(Decimal.zero) { $0 + $1.amount }).doubleValue
        
        Chart(categoryData, id: \.category) { item in
            let amountDouble = NSDecimalNumber(decimal: item.amount).doubleValue
            let percentage = totalAmount > 0 ? (amountDouble / totalAmount * 100) : 0
            
            SectorMark(
                angle: .value("Amount", amountDouble),
                innerRadius: .ratio(0.45),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(by: .value("Category", item.category.displayName))
            .annotation(position: .overlay) {
                // 割合が5%以上の項目のみ表示し、文字被りを防ぐ
                if percentage >= 5.0 {
                    Text(item.category.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        // グラフの色味に合わせた半透明色
                        .background(item.category.color.opacity(0.6))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(height: 220)
        .padding(.vertical, 8)
        .chartLegend(.hidden)
    }
    
    @ViewBuilder
    private var listByCategory: some View {
        VStack(spacing: 10) {
            let totalAmount = categoryData.reduce(Decimal.zero) { $0 + $1.amount }
            ForEach(categoryData, id: \.category.id) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 10, height: 10)
                    
                    Text(item.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(CurrencyHelper.formatted(amount: item.amount))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                    
                    let percentage = totalAmount > 0 ? (NSDecimalNumber(decimal: item.amount).doubleValue / NSDecimalNumber(decimal: totalAmount).doubleValue * 100) : 0
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Service Mode
    
    @ViewBuilder
    private var chartByService: some View {
        let totalAmount = NSDecimalNumber(decimal: serviceData.reduce(Decimal.zero) { $0 + $1.amount }).doubleValue
        
        Chart(Array(serviceData.enumerated()), id: \.element.id) { index, item in
            let amountDouble = NSDecimalNumber(decimal: item.amount).doubleValue
            let percentage = totalAmount > 0 ? (amountDouble / totalAmount * 100) : 0
            let itemColor = chartColors[index % chartColors.count]
            
            SectorMark(
                angle: .value("Amount", amountDouble),
                innerRadius: .ratio(0.45),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(itemColor)
            .annotation(position: .overlay) {
                // 割合が5%以上の項目のみ表示し、文字被りを防ぐ
                if percentage >= 5.0 {
                    Text(item.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        // グラフの色味に合わせた半透明色
                        .background(itemColor.opacity(0.6))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(height: 220)
        .padding(.vertical, 8)
        .chartLegend(.hidden)
    }
    
    @ViewBuilder
    private var listByService: some View {
        VStack(spacing: 10) {
            let totalAmount = serviceData.reduce(Decimal.zero) { $0 + $1.amount }
            ForEach(Array(serviceData.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(chartColors[index % chartColors.count])
                        .frame(width: 10, height: 10)
                    
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(CurrencyHelper.formatted(amount: item.amount))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                    
                    let percentage = totalAmount > 0 ? (NSDecimalNumber(decimal: item.amount).doubleValue / NSDecimalNumber(decimal: totalAmount).doubleValue * 100) : 0
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview {
    DistributionChartView(
        mode: .constant(.byService),
        categoryData: [
            (.entertainment, Decimal(2500)),
            (.work, Decimal(1500))
        ],
        serviceData: [
            (id: "Netflix", name: "Netflix", amount: Decimal(1500), iconName: "film", color: .purple),
            (id: "Spotify", name: "Spotify", amount: Decimal(1000), iconName: "music.note", color: .green)
        ]
    )
    .padding()
}
