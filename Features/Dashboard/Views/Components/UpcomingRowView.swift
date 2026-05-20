//
//  UpcomingRowView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// 直近の請求予定リストの各行を表示する子View。
/// アイコンに背景色を敷き、より視認性を高くモダンなデザインに仕上げます。
struct UpcomingRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 16) {
            // アイコン背景のスタイリング
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: subscription.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subscription.nextPaymentDate, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyHelper.formatted(amount: subscription.amount))
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
    }
}
