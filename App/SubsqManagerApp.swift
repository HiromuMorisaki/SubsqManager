//
//  SubsqManagerApp.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct SubsqManagerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.createForApp()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue

    var body: some Scene {
        WindowGroup {
            let currentTheme = AppTheme(rawValue: appThemeRawValue) ?? .neonGreen
            
            ContentView()
                .tint(currentTheme.color)
                .accentColor(currentTheme.color)
                .task {
                    // アプリ初回起動時に通知許可ダイアログを表示する。
                    await NotificationService.requestAuthorization()
                    
                    // ウィジェット用にテーマ情報を共有AppGroupコンテナに書き込む
                    let sharedDefaults = UserDefaults(suiteName: "group.com.h-morisaki.SubsqManager")
                    sharedDefaults?.set(appThemeRawValue, forKey: "appTheme")
                }
                .onChange(of: appThemeRawValue) { oldValue, newValue in
                    let sharedDefaults = UserDefaults(suiteName: "group.com.h-morisaki.SubsqManager")
                    sharedDefaults?.set(newValue, forKey: "appTheme")
                    // ウィジェットの再描画を要求
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
