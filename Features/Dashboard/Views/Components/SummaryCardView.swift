//
//  SummaryCardView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// 月額合計・年額合計を表示するカードUI。
/// モダンなグラスモーフィズム風の背景とシャドウを適用し、プレミアム感を演出します。
struct SummaryCardView: View {
    let title: String
    let amount: Decimal
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                    .font(.headline)
                    .padding(8)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(CurrencyHelper.formatted(amount: amount))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        // より洗練された背景とシャドウの適用
        .background(Color(.systemBackground)) // macOS対応の白/黒背景
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
