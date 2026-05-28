//
//  SharedModelContainer.swift
//  SubsqManagerWidget
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation
import SwiftData

/// メインアプリとウィジェットで共有するModelContainerを生成するヘルパー。
/// App Group のコンテナを使用することで、同じSwiftDataストアにアクセスする。
enum SharedModelContainer {

    /// App Group の識別子
    static let appGroupID = "group.com.h-morisaki.SubsqManager"

    /// 共有コンテナのURL
    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// 共有ModelContainerを生成する
    static func create() throws -> ModelContainer {
        let schema = Schema([Subscription.self, ReductionHistory.self])
        let config = ModelConfiguration(
            schema: schema,
            url: containerURL.appendingPathComponent("SubsqManager.store"),
            allowsSave: false // ウィジェットからは読み取り専用
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// メインアプリ用: 書き込み可能な共有ModelContainerを生成する
    static func createForApp() throws -> ModelContainer {
        let schema = Schema([Subscription.self, ReductionHistory.self])
        let config = ModelConfiguration(
            schema: schema,
            url: containerURL.appendingPathComponent("SubsqManager.store"),
//            cloudKitDatabase: .none // 一旦 .none にして、Xcode側でiCloud (CloudKit) のCapabilityが設定されるまでの起動時クラッシュを防止します
            cloudKitDatabase: .private("iCloud.com.h-morisaki.SubsqManager")
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
