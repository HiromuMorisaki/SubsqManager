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
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.bar")
                }

            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }

            SubscriptionListView()
                .tabItem {
                    Label("サブスク", systemImage: "list.bullet")
                }

            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "chart.pie")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
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
