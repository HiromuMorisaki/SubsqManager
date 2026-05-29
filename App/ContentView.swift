//
//  ContentView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// アプリのルートView。
/// TabViewで「ダッシュボード」と「サブスク一覧」を切り替える。
///
/// ### TabView について
/// iOSの画面下部にタブバーを表示し、タップで画面を切り替えるコンテナView。
/// 各タブには Label（テキスト + SF Symbol）を設定し、
/// .tag() で選択状態を管理する。
struct ContentView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true }
    ) private var subscriptions: [Subscription]

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.bar")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(1)

            SubscriptionListView()
                .tabItem {
                    Label("サブスク", systemImage: "list.bullet")
                }
                .tag(2)

            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "chart.pie")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowReviewWizard"))) { _ in
            selectedTab = 0 // ダッシュボードタブへ切り替え
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToSettingsTab"))) { _ in
            selectedTab = 4 // 設定タブへ切り替え
        }
        .task {
            // 重複サブスクリプションを自動クリーンアップ（自己修復機能）
            SubscriptionDeduplicator.deduplicateActiveSubscriptions(using: modelContext)
            
            // ASO対策: アプリ起動回数を増やし、起動条件（起動3回以上 ＆ サブスク1件以上）クリア時に2秒遅延でレビューを自動要求
            ReviewRequestService.shared.incrementLaunchCount()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ReviewRequestService.shared.requestReviewIfLaunchConditionsMet(activeSubscriptionCount: subscriptions.count)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: .init(get: { !hasSeenOnboarding }, set: { _ in })) {
            OnboardingView()
        }
        #else
        .sheet(isPresented: .init(get: { !hasSeenOnboarding }, set: { _ in })) {
            OnboardingView()
                .frame(minWidth: 500, minHeight: 400)
        }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
