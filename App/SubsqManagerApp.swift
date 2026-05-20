//
//  SubsqManagerApp.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

@main
struct SubsqManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedModelContainer.createForApp()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // アプリ初回起動時に通知許可ダイアログを表示する。
                    // .task はViewの表示時に一度だけ非同期処理を実行する修飾子。
                    await NotificationService.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
