import XCTest
@testable import SubsqManager

final class SubscriptionPresetTests: XCTestCase {
    
    /// プリセットデータベースが正常にロードされ、空でないことを確認する
    func testPresetsLoadSuccessfully() {
        let presets = SubscriptionPreset.defaultPresets
        XCTAssertFalse(presets.isEmpty, "プリセットJSONの読み込みに失敗しているか、空です。")
        XCTAssertGreaterThanOrEqual(presets.count, 300, "プリセット件数が300件未満です（現在の件数: \(presets.count)）")
        print("✅ 読み込まれたプリセット件数: \(presets.count)")
    }
    
    /// プリセットのIDが一意であることを検証する
    func testPresetIDsAreUnique() {
        let presets = SubscriptionPreset.defaultPresets
        let ids = presets.map { $0.id }
        let uniqueIDs = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIDs.count, "プリセットIDに重複が存在します。")
        
        // 重複しているIDの特定とデバッグ出力
        if ids.count != uniqueIDs.count {
            var seen = Set<String>()
            var duplicates = Set<String>()
            for id in ids {
                if seen.contains(id) {
                    duplicates.insert(id)
                } else {
                    seen.insert(id)
                }
            }
            XCTFail("重複するプリセットID: \(duplicates)")
        }
    }
    
    /// すべてのプランのIDが一意であることを検証する
    func testPlanIDsAreUnique() {
        let presets = SubscriptionPreset.defaultPresets
        var planIDs = [String]()
        
        for preset in presets {
            for plan in preset.plans {
                planIDs.append(plan.id)
            }
        }
        
        let uniquePlanIDs = Set(planIDs)
        XCTAssertEqual(planIDs.count, uniquePlanIDs.count, "プランIDに重複が存在します。")
        
        if planIDs.count != uniquePlanIDs.count {
            var seen = Set<String>()
            var duplicates = Set<String>()
            for id in planIDs {
                if seen.contains(id) {
                    duplicates.insert(id)
                } else {
                    seen.insert(id)
                }
            }
            XCTFail("重複するプランID: \(duplicates)")
        }
    }
    
    /// 各プリセットに少なくとも1つのプランが定義されていることを確認する
    func testEveryPresetHasAtLeastOnePlan() {
        let presets = SubscriptionPreset.defaultPresets
        for preset in presets {
            XCTAssertFalse(preset.plans.isEmpty, "プリセット '\(preset.name)' (\(preset.id)) にプランが定義されていません。")
        }
    }
    
    /// 新カテゴリ '.lessons'（習い事・教室）が機能していることを検証する
    func testLessonsCategoryIsActive() {
        let presets = SubscriptionPreset.defaultPresets
        let lessonsPresets = presets.filter { $0.category == .lessons }
        
        XCTAssertFalse(lessonsPresets.isEmpty, "lessons（習い事・教室）カテゴリのプリセットが見つかりません。")
        XCTAssertGreaterThanOrEqual(lessonsPresets.count, 15, "lessonsカテゴリのプリセット数が足りません（現在の件数: \(lessonsPresets.count)）")
        
        // 代表的なサービスの存在を確認
        let lessonNames = lessonsPresets.map { $0.name }
        XCTAssertTrue(lessonNames.contains("公文式（くもん）"), "公文式が習い事カテゴリに含まれていません。")
        XCTAssertTrue(lessonNames.contains("ヤマハ音楽教室"), "ヤマハ音楽教室が習い事カテゴリに含まれていません。")
    }
    
    /// カテゴリ別グループ化が機能していることを検証する
    func testGroupedByCategory() {
        let grouped = SubscriptionPreset.groupedByCategory
        
        XCTAssertFalse(grouped.isEmpty, "カテゴリ別グループ化が空です。")
        XCTAssertNotNil(grouped[.lessons], "lessonsカテゴリのグループが存在しません。")
        XCTAssertGreaterThan(grouped[.lessons]?.count ?? 0, 0, "lessonsカテゴリグループの要素数が0です。")
    }
}
