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
    @State private var showingAddView = false
    @State private var showingImportView = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarHeader
                    
                    remainingPaymentsHeader
                    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingImportView = true
                    } label: {
                        Label("外部連携", systemImage: "square.and.arrow.down.on.square")
                    }
                }
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
            .sheet(isPresented: $showingImportView) {
                CalendarImportView()
            }
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

            HStack(spacing: 8) {
                Text(monthEmoji(from: viewModel.currentMonth))
                    .font(.title2)
                Text(monthYearString(from: viewModel.currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            Button(action: { viewModel.moveToNextMonth() }) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
        .padding(.horizontal)
    }

    /// カレンダー上部の月次残り支払いサマリーヘッダー
    private var remainingPaymentsHeader: some View {
        let remaining = viewModel.remainingPayments(from: subscriptions)
        
        return HStack {
            Spacer()
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("残り支払件数:")
                    Text("\(remaining.count)件")
                        .fontWeight(.bold)
                }
                
                Text("|")
                    .foregroundStyle(.secondary.opacity(0.5))
                
                HStack(spacing: 4) {
                    Image(systemName: "yensign.circle")
                    Text("残り支払い合計:")
                    Text(CurrencyHelper.formatted(amount: remaining.total))
                        .fontWeight(.bold)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(Capsule())
            Spacer()
        }
        .padding(.horizontal)
    }

    /// 曜日のヘッダー（日〜土）
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays.indices, id: \.self) { index in
                Text(weekdays[index])
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(weekdayColor(for: index))
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
                let daySubs = viewModel.subscriptions(for: calDate.date, from: subscriptions)
                let paymentAmount = viewModel.totalAmount(for: daySubs)
                let isSelected = Calendar.current.isDate(calDate.date, inSameDayAs: viewModel.selectedDate)
                
                CalendarDateCell(
                    date: calDate,
                    isSelected: isSelected,
                    paymentAmount: paymentAmount
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
                    HStack {
                        Image(systemName: sub.iconName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sub.name)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let days = daysRemaining(to: viewModel.selectedDate) {
                                let badgeText: String = {
                                    if days == 0 { return "今日" }
                                    if days == 1 { return "明日" }
                                    return "あと\(days)日"
                                }()
                                let badgeColor: Color = {
                                    if days == 0 { return .red }
                                    if days == 1 { return .orange }
                                    return .blue
                                }()
                                
                                Text(badgeText)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(badgeColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                Text("支払済")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        
                        Spacer()
                        
                        Text(CurrencyHelper.formatted(amount: sub.amount))
                            .fontWeight(.semibold)
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
    
    private func monthEmoji(from date: Date) -> String {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 1: return "🎍"
        case 2: return "⛄️"
        case 3: return "🌸"
        case 4: return "🌷"
        case 5: return "🎏"
        case 6: return "☔️"
        case 7: return "🎋"
        case 8: return "🌻"
        case 9: return "🌕"
        case 10: return "🎃"
        case 11: return "🍁"
        case 12: return "🎄"
        default: return "🗓️"
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func weekdayColor(for index: Int) -> Color {
        if index == 0 { return .red } // 日曜
        if index == 6 { return .blue } // 土曜
        return .secondary
    }

    private func daysRemaining(to targetDate: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: targetDate)
        
        guard target >= today else { return nil }
        
        let components = calendar.dateComponents([.day], from: today, to: target)
        return components.day
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
