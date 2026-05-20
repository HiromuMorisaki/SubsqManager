//
//  CategoryChartView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import Charts

/// カテゴリ別の支出割合を示す円グラフView。
/// Swift Charts を使用して構築。
struct CategoryChartView: View {

    /// グラフに表示するデータ (カテゴリ, 月額合計)
    let data: [(category: Category, amount: Decimal)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別支出 (月額)")
                .font(.headline)

            if data.isEmpty {
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // iOS 17以降で利用可能な SectorMark による円グラフ
                Chart(data, id: \.category) { item in
                    // Decimal を Double に変換（Swift ChartsはDecimalを直接扱えないため）
                    let amountDouble = NSDecimalNumber(decimal: item.amount).doubleValue
                    
                    SectorMark(
                        angle: .value("Amount", amountDouble),
                        innerRadius: .ratio(0.6), // ドーナツ型にする
                        angularInset: 1.5 // セクター間の隙間
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Category", item.category.displayName))
                }
                .frame(height: 200)
                .padding(.vertical)
                // 凡例のカスタマイズ（下部に表示）
                .chartLegend(position: .bottom, alignment: .center, spacing: 16)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    CategoryChartView(data: [
        (.entertainment, Decimal(2500)),
        (.work, Decimal(1500)),
        (.lifestyle, Decimal(1000)),
        (.education, Decimal(0)),
        (.other, Decimal(500))
    ])
    .padding()
}
