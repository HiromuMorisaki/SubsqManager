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
    let hasPayment: Bool

    var body: some View {
        VStack(spacing: 4) {
            // 日付の数字
            Text(dayString)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                // 当月外の日付はグレー表示
                .foregroundStyle(date.isCurrentMonth ? .primary : .secondary)
                .frame(width: 32, height: 32)
                // 選択時の背景と文字色
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundStyle(isSelected ? .white : (date.isCurrentMonth ? .primary : .secondary))
                .clipShape(Circle())

            // 支払いがある日のインジケーター（ドット）
            Circle()
                .fill(hasPayment ? Color.accentColor : Color.clear)
                .frame(width: 6, height: 6)
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
}

// MARK: - Preview

#Preview {
    HStack {
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: true),
            isSelected: false,
            hasPayment: true
        )
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: true),
            isSelected: true,
            hasPayment: false
        )
        CalendarDateCell(
            date: CalendarDate(date: Date(), isCurrentMonth: false),
            isSelected: false,
            hasPayment: false
        )
    }
    .padding()
}
