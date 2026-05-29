//
//  SubsqManagerWidget.swift
//  SubsqManagerWidget
//
//  Created by 森崎大夢 on 2026/05/20.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Local Widget Theme Configuration

/// ウィジェット用に最適化した、アプリ共通テーマのダーク・ネオン表示用アダプター
struct WidgetTheme {
    let rawValue: String
    
    /// テーマのアクセントカラー
    var color: Color {
        switch rawValue {
        case "neonPurple": return .purple
        case "neonPink": return .pink
        case "neonBlue": return .blue
        case "neonGreen": return Color(red: 0.05, green: 0.82, blue: 0.52) // 視認性とネオン感をさらに高めたグリーン
        case "cyberpunkYellow": return Color(red: 1.0, green: 0.8, blue: 0.0)
        default: return Color(red: 0.05, green: 0.82, blue: 0.52)
        }
    }
    
    /// ウィジェット背景に用いる、深みのあるプレミアムなグラデーション
    var gradientColors: [Color] {
        switch rawValue {
        case "neonPurple": 
            return [Color(red: 0.07, green: 0.08, blue: 0.18), Color(red: 0.16, green: 0.08, blue: 0.28)]
        case "neonPink": 
            return [Color(red: 0.09, green: 0.06, blue: 0.09), Color(red: 0.26, green: 0.06, blue: 0.12)]
        case "neonBlue": 
            return [Color(red: 0.05, green: 0.09, blue: 0.18), Color(red: 0.08, green: 0.20, blue: 0.35)]
        case "neonGreen": 
            return [Color(red: 0.04, green: 0.08, blue: 0.07), Color(red: 0.05, green: 0.22, blue: 0.16)]
        case "cyberpunkYellow": 
            return [Color(red: 0.08, green: 0.08, blue: 0.06), Color(red: 0.24, green: 0.16, blue: 0.04)]
        default: 
            return [Color(red: 0.04, green: 0.08, blue: 0.07), Color(red: 0.05, green: 0.22, blue: 0.16)]
        }
    }
}

// MARK: - Timeline Entry

struct SubsqEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Decimal
    let privateTotal: Decimal
    let expenseTotal: Decimal
    let activeCount: Int
    let upcomingSubscriptions: [UpcomingItem]
    let totalSavings: Decimal
    let themeRawValue: String

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
            monthlyTotal: 14845,
            privateTotal: 12845,
            expenseTotal: 2000,
            activeCount: 8,
            upcomingSubscriptions: [
                .init(name: "Netflix (スタンダード)", amount: 1590, nextPaymentDate: Date(), iconName: "film", categoryColor: "entertainment"),
                .init(name: "Apple Music (ファミリー)", amount: 1680, nextPaymentDate: Date(), iconName: "music.note", categoryColor: "music"),
                .init(name: "みてね プレミアム (月額)", amount: 480, nextPaymentDate: Date(), iconName: "photo", categoryColor: "kids"),
            ],
            totalSavings: 2360,
            themeRawValue: "neonGreen"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubsqEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubsqEntry>) -> Void) {
        let entry = fetchEntry()

        // 毎日深夜0時に更新
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func fetchEntry() -> SubsqEntry {
        let appGroupID = "group.com.h-morisaki.SubsqManager"
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        let totalSavingsDouble = sharedDefaults?.double(forKey: "totalSavingsAmount") ?? 0
        let totalSavings = Decimal(totalSavingsDouble)
        
        // アプリから共有されたアクティブなテーマを取得
        let themeRawValue = sharedDefaults?.string(forKey: "appTheme") ?? "neonGreen"

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
                upcomingSubscriptions: upcoming,
                totalSavings: totalSavings,
                themeRawValue: themeRawValue
            )
        } catch {
            return SubsqEntry(
                date: Date(),
                monthlyTotal: 0,
                privateTotal: 0,
                expenseTotal: 0,
                activeCount: 0,
                upcomingSubscriptions: [],
                totalSavings: totalSavings,
                themeRawValue: themeRawValue
            )
        }
    }
}

// MARK: - Small Widget View（月額合計）

struct MonthlyTotalWidgetView: View {
    var entry: SubsqEntry
    
    private var theme: WidgetTheme {
        WidgetTheme(rawValue: entry.themeRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー部（アイコンとテキストを少し大きく）
            HStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.color)
                Text("月額合計")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // 金額表示部（フォントサイズを22から28へ大幅に拡大し、極太に）
            VStack(alignment: .leading, spacing: 4) {
                Text(CurrencyHelper.formatted(amount: entry.monthlyTotal))
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                // 経費情報、または登録件数をカプセル風のデザインで美しく表示
                if entry.expenseTotal > 0 {
                    HStack(spacing: 3) {
                        Text("内 経費:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(CurrencyHelper.formatted(amount: entry.expenseTotal))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.06))
                    .cornerRadius(4)
                } else {
                    Text("\(entry.activeCount)件のサブスク")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.08))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.all, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget View（次回請求）

struct UpcomingWidgetView: View {
    var entry: SubsqEntry
    
    private var theme: WidgetTheme {
        WidgetTheme(rawValue: entry.themeRawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー（タイトルフォントサイズを拡大）
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.color)
                Text("次回の請求")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
                
                // 右上合計金額のカプセルタグを少し大きめに修正
                HStack(spacing: 4) {
                    Text("合計")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(CurrencyHelper.formatted(amount: entry.monthlyTotal))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(theme.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .padding(.bottom, 2)

            if entry.upcomingSubscriptions.isEmpty {
                Spacer()
                Text("予定されている請求はありません")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(entry.upcomingSubscriptions.enumerated()), id: \.offset) { _, item in
                        let category = Category(rawValue: item.categoryColor) ?? .other
                        
                        HStack(spacing: 8) {
                            // 左端のカテゴリ別縦線アクセント（ピル）
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(category.color)
                                .frame(width: 3.5, height: 18)
                            
                            // アイコンの円形カラーバックドロップ（サイズを少し拡大）
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.12))
                                    .frame(width: 24, height: 24)
                                Image(systemName: item.iconName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(category.color)
                            }
                            
                            // サービス名（フォントサイズを13へ拡大、太字）
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            
                            Spacer()
                            
                            // 請求予定日（フォントサイズを11へ拡大）
                            Text(item.nextPaymentDate, format: .dateTime.month().day())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.trailing, 2)
                            
                            // 金額（フォントサイズを14へ大幅拡大し、極太に）
                            Text(CurrencyHelper.formatted(amount: item.amount))
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 6) // 行の上下パディングを広げ、窮屈さを解消
                        .padding(.horizontal, 8)
                        .background(.white.opacity(0.06)) // 透明度を少し上げ、カード感を強調
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.all, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Savings Widget View（削減実績）

struct SavingsWidgetView: View {
    var entry: SubsqEntry
    @Environment(\.widgetFamily) var family
    
    private var theme: WidgetTheme {
        WidgetTheme(rawValue: entry.themeRawValue)
    }

    var body: some View {
        if family == .systemSmall {
            VStack(alignment: .leading, spacing: 0) {
                // ヘッダー（タイトルフォントサイズを拡大）
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.color)
                    Text("削減実績")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // 削減金額表示（フォントサイズを20から28へ大幅に拡大し、極太に）
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎉 累計")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.color)
                    
                    Text(CurrencyHelper.formatted(amount: entry.totalSavings))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text("削減中！")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.all, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            // Medium サイズ
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme.color)
                        Text("削減実績")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("これまでの固定費見直しによって削減できた、毎月の累計額です！")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // 動機づけを高めるモチベーションボックス
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🎉 累計削減額")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.color.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text(CurrencyHelper.formatted(amount: entry.totalSavings))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text("削減に成功！")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.all, 10)
                .background(.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.color.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(.all, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Widget Configurations

/// Small ウィジェット: 月額合計を表示
struct SubsqMonthlyWidget: Widget {
    let kind = "SubsqMonthlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsqTimelineProvider()) { entry in
            let theme = WidgetTheme(rawValue: entry.themeRawValue)
            MonthlyTotalWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
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
            let theme = WidgetTheme(rawValue: entry.themeRawValue)
            UpcomingWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("次回の請求")
        .description("次に請求が来るサブスクリプションを表示します")
        .supportedFamilies([.systemMedium])
    }
}

/// Small/Medium ウィジェット: 削減実績を表示
struct SubsqSavingsWidget: Widget {
    let kind = "SubsqSavingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsqTimelineProvider()) { entry in
            let theme = WidgetTheme(rawValue: entry.themeRawValue)
            SavingsWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("削減実績")
        .description("これまでの固定費削減の累計額を表示してモチベーションを高めます")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
