//
//  SubsqManagerWidget.swift
//  SubsqManagerWidget
//
//  Created by 森崎大夢 on 2026/05/20.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

/// ウィジェットに表示するデータを格納するエントリ
struct SubsqEntry: TimelineEntry {
    let date: Date
    /// 月額合計金額（すべて）
    let monthlyTotal: Decimal
    /// 月額合計（プライベート）
    let privateTotal: Decimal
    /// 月額合計（経費）
    let expenseTotal: Decimal
    /// アクティブなサブスク数
    let activeCount: Int
    /// 次回請求が近いサブスク（上位3件）
    let upcomingSubscriptions: [UpcomingItem]

    /// 次回請求サブスクの簡易表現
    struct UpcomingItem {
        let name: String
        let amount: Decimal
        let nextPaymentDate: Date
        let iconName: String
        let categoryColor: String // Category.rawValue
    }
}

// MARK: - Timeline Provider

struct SubsqTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> SubsqEntry {
        SubsqEntry(
            date: Date(),
            monthlyTotal: 5980,
            privateTotal: 2980,
            expenseTotal: 3000,
            activeCount: 5,
            upcomingSubscriptions: [
                .init(name: "Netflix", amount: 1490, nextPaymentDate: Date(), iconName: "film", categoryColor: "entertainment"),
                .init(name: "Spotify", amount: 980, nextPaymentDate: Date(), iconName: "music.note", categoryColor: "entertainment"),
                .init(name: "iCloud+", amount: 400, nextPaymentDate: Date(), iconName: "cloud", categoryColor: "other"),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubsqEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubsqEntry>) -> Void) {
        let entry = fetchEntry()

        // 次の午前0時に更新（日付が変わったタイミング）
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    /// SwiftData からサブスクデータを取得してエントリを生成する
    private func fetchEntry() -> SubsqEntry {
        do {
            let container = try SharedModelContainer.create()
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Subscription>(
                predicate: #Predicate { $0.isActive == true },
                sortBy: [SortDescriptor(\.nextPaymentDate)]
            )
            let subscriptions = try context.fetch(descriptor)

            let monthlyTotal = subscriptions.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            let privateTotal = subscriptions.filter { !$0.isExpense }.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            let expenseTotal = subscriptions.filter { $0.isExpense }.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            
            let upcoming = subscriptions.prefix(3).map { sub in
                SubsqEntry.UpcomingItem(
                    name: sub.name,
                    amount: sub.amount,
                    nextPaymentDate: sub.nextPaymentDate,
                    iconName: sub.iconName,
                    categoryColor: sub.category.rawValue
                )
            }

            return SubsqEntry(
                date: Date(),
                monthlyTotal: monthlyTotal,
                privateTotal: privateTotal,
                expenseTotal: expenseTotal,
                activeCount: subscriptions.count,
                upcomingSubscriptions: upcoming
            )
        } catch {
            // データ取得失敗時はデフォルト値
            return SubsqEntry(
                date: Date(),
                monthlyTotal: 0,
                privateTotal: 0,
                expenseTotal: 0,
                activeCount: 0,
                upcomingSubscriptions: []
            )
        }
    }
}

// MARK: - Small Widget View（月額合計）

struct MonthlyTotalWidgetView: View {
    var entry: SubsqEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(.blue)
                Text("月額合計")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyHelper.formatted(amount: entry.monthlyTotal))
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if entry.expenseTotal > 0 {
                HStack(spacing: 4) {
                    Text("経費:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyHelper.formatted(amount: entry.expenseTotal))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("\(entry.activeCount)件のサブスク")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
    }
}

// MARK: - Medium Widget View（次回請求）

struct UpcomingWidgetView: View {
    var entry: SubsqEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.orange)
                Text("次回の請求")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("月額合計 \(CurrencyHelper.formatted(amount: entry.monthlyTotal))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.upcomingSubscriptions.isEmpty {
                Spacer()
                Text("サブスクがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(entry.upcomingSubscriptions.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 10) {
                        Image(systemName: item.iconName)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 20)

                        Text(item.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Spacer()

                        Text(item.nextPaymentDate, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(CurrencyHelper.formatted(amount: item.amount))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(4)
    }
}

// MARK: - Widget Definitions

/// Small ウィジェット: 月額合計を表示
struct SubsqMonthlyWidget: Widget {
    let kind = "SubsqMonthlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsqTimelineProvider()) { entry in
            MonthlyTotalWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("月額合計")
        .description("サブスクリプションの月額合計を表示します")
        .supportedFamilies([.systemSmall])
    }
}

/// Medium ウィジェット: 次回請求を表示
struct SubsqUpcomingWidget: Widget {
    let kind = "SubsqUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsqTimelineProvider()) { entry in
            UpcomingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("次回の請求")
        .description("次に請求が来るサブスクリプションを表示します")
        .supportedFamilies([.systemMedium])
    }
}
