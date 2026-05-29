//
//  WidgetDataShareHelper.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/28.
//

import Foundation
import SwiftData
import WidgetKit

final class WidgetDataShareHelper {
    static let appGroupID = "group.com.h-morisaki.SubsqManager"
    static let totalSavingsKey = "totalSavingsAmount"
    
    /// 削減履歴の全レコードから月額削減額の累計を再計算し、UserDefaults（Shared App Group）に保存してウィジェットをリロードします。
    @MainActor
    static func updateSharedSavingsAmount(using modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ReductionHistory>()
            let histories = try modelContext.fetch(descriptor)
            let totalReducedMonthly = histories.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            
            let sharedDefaults = UserDefaults(suiteName: appGroupID)
            sharedDefaults?.set(NSDecimalNumber(decimal: totalReducedMonthly).doubleValue, forKey: totalSavingsKey)
            
            // ウィジェットに反映するためにタイムラインを再読込
            WidgetCenter.shared.reloadAllTimelines()
            
            print("WidgetDataShareHelper: 🎉 累計 ¥\(totalReducedMonthly) 削減中 をウィジェットと同期しました")
        } catch {
            print("WidgetDataShareHelper: 同期エラー - \(error)")
        }
    }
}
