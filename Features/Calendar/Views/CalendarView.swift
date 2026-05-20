//
//  CalendarView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// カレンダー画面全体のView。
/// LazyVGridによるカレンダー表示と、選択された日付のサブスク一覧を表示する。
struct CalendarView: View {

    @Query(filter: #Predicate<Subscription> { $0.isActive == true })
    private var subscriptions: [Subscription]

    @State private var viewModel = CalendarViewModel()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarHeader
                    
                    VStack(spacing: 8) {
                        weekdayHeader
                        calendarGrid
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    selectedDateDetails
                }
                .padding(.vertical)
            }
            .navigationTitle("カレンダー")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - カレンダーUI

    /// 年月表示と前月・次月移動ボタン
    private var calendarHeader: some View {
        HStack {
            Button(action: { viewModel.moveToPreviousMonth() }) {
                Image(systemName: "chevron.left")
                    .padding()
            }

            Spacer()

            Text(monthYearString(from: viewModel.currentMonth))
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: { viewModel.moveToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
        .padding(.horizontal)
    }

    /// 曜日のヘッダー（日〜土）
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 8)
    }

    /// 7カラムの日付グリッド
    private var calendarGrid: some View {
        let dates = viewModel.generateCalendarDates()
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(dates) { calDate in
                let hasPayment = !viewModel.subscriptions(for: calDate.date, from: subscriptions).isEmpty
                let isSelected = Calendar.current.isDate(calDate.date, inSameDayAs: viewModel.selectedDate)
                
                CalendarDateCell(
                    date: calDate,
                    isSelected: isSelected,
                    hasPayment: hasPayment
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedDate = calDate.date
                    }
                }
            }
        }
    }

    // MARK: - 選択日の詳細表示

    /// 選択された日付に支払いが予定されているサブスクリストと合計金額
    private var selectedDateDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            let selectedSubs = viewModel.subscriptions(for: viewModel.selectedDate, from: subscriptions)
            
            HStack {
                Text(dateString(from: viewModel.selectedDate))
                    .font(.headline)
                
                Spacer()
                
                if !selectedSubs.isEmpty {
                    let total = viewModel.totalAmount(for: selectedSubs)
                    Text("合計: \(CurrencyHelper.formatted(amount: total))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            if selectedSubs.isEmpty {
                ContentUnavailableView {
                    Label("支払いなし", systemImage: "checkmark.circle")
                } description: {
                    Text("この日の支払いは予定されていません。")
                }
                .frame(height: 150)
            } else {
                ForEach(selectedSubs) { sub in
                    // SubscriptionRowViewを再利用し、月額ではなくその日の支払い額を表示するように調整
                    // ただしSubscriptionRowViewは内部で sub.amount を表示しているためそのまま使える
                    HStack {
                        Image(systemName: sub.iconName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 30)
                        
                        Text(sub.name)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(CurrencyHelper.formatted(amount: sub.amount))
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - ヘルパー

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
