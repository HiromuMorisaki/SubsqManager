//
//  CalendarDateCell.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// カレンダーの1日分を表示するセルView。
struct CalendarDateCell: View {
    let date: CalendarDate
    let isSelected: Bool
    let paymentAmount: Decimal

    @AppStorage("currencyCode") private var currencyCode = "JPY"

    private var isYenLike: Bool {
        currencyCode == "JPY" || currencyCode == "KRW"
    }

    private var dotSize: CGFloat {
        if paymentAmount == 0 { return 0 }
        let amountDouble = NSDecimalNumber(decimal: paymentAmount).doubleValue
        
        if isYenLike {
            if amountDouble < 2000 {
                return 4
            } else if amountDouble < 10000 {
                return 6
            } else {
                return 8
            }
        } else {
            if amountDouble < 20 {
                return 4
            } else if amountDouble < 100 {
                return 6
            } else {
                return 8
            }
        }
    }

    private var dotOpacity: Double {
        if paymentAmount == 0 { return 0 }
        let amountDouble = NSDecimalNumber(decimal: paymentAmount).doubleValue
        
        if isYenLike {
            if amountDouble < 2000 {
                return 0.5
            } else if amountDouble < 10000 {
                return 0.8
            } else {
                return 1.0
            }
        } else {
            if amountDouble < 20 {
                return 0.5
            } else if amountDouble < 100 {
                return 0.8
            } else {
                return 1.0
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // 日付の数字
            Text(dayString)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundStyle(textColor)
                .frame(width: 32, height: 32)
                // 選択時の背景
                .background(isSelected ? Color.accentColor : Color.clear)
                .clipShape(Circle())

            // 支払いがある日のインジケーター（ドット）
            ZStack {
                if paymentAmount > 0 {
                    Circle()
                        .fill(Color.accentColor.opacity(dotOpacity))
                        .frame(width: dotSize, height: dotSize)
                } else {
                    Color.clear
                }
            }
            .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
        // タップ領域を広げる
        .contentShape(Rectangle())
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date.date)
    }

    private var textColor: Color {
        if isSelected { return .white }
        
        let weekday = Calendar.current.component(.weekday, from: date.date)
        let baseColor: Color
        if weekday == 1 {
            baseColor = .red
        } else if weekday == 7 {
            baseColor = .blue
        } else {
            baseColor = .primary
        }
        
        return date.isCurrentMonth ? baseColor : baseColor.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    HStack {
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: true),
            isSelected: false,
            paymentAmount: Decimal(1500)
        )
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: true),
            isSelected: true,
            paymentAmount: Decimal(0)
        )
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: false),
            isSelected: false,
            paymentAmount: Decimal(12000)
        )
    }
    .padding()
}
