//
//  OCRServiceTests.swift
//  SubsqManagerTests
//

import XCTest
@testable import SubsqManager

final class OCRServiceTests: XCTestCase {
    
    private var ocrService: OCRService!
    
    override func setUp() {
        super.setUp()
        ocrService = OCRService()
    }
    
    override func tearDown() {
        ocrService = nil
        super.tearDown()
    }
    
    // MARK: - Smart Date Parsing & Year Inference Tests
    
    /// 年が明示されている日付（例: 「2027年5月19日」や「27年5月19日」）のパーステスト
    func testParseSmartDate_WithExplicitYear() {
        // "更新日：2027年5月19日" の形式
        let elements = [
            OCRService.TextElement(text: "Test App", y: 0.1),
            OCRService.TextElement(text: "¥12,800", y: 0.2),
            OCRService.TextElement(text: "更新日：2027年5月19日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        XCTAssertEqual(item.name, "Test App")
        XCTAssertEqual(item.amount, 12800)
        XCTAssertEqual(item.billingCycle, .yearly) // 5000円超 ＆ 年額自動検知
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: item.nextPaymentDate), 2027)
        XCTAssertEqual(calendar.component(.month, from: item.nextPaymentDate), 5)
        XCTAssertEqual(calendar.component(.day, from: item.nextPaymentDate), 19)
    }
    
    /// 2桁表記の年（例: 「27年5月19日」）のパーステスト
    func testParseSmartDate_WithTwoDigitYear() {
        let elements = [
            OCRService.TextElement(text: "Test App", y: 0.1),
            OCRService.TextElement(text: "¥12,800", y: 0.2),
            OCRService.TextElement(text: "更新日：27年5月19日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: item.nextPaymentDate), 2027)
        XCTAssertEqual(calendar.component(.month, from: item.nextPaymentDate), 5)
        XCTAssertEqual(calendar.component(.day, from: item.nextPaymentDate), 19)
    }
    
    /// 年が省略されている日付で、今日以降の月日（例: 「6月7日」）のスマート推論テスト
    /// ※ 現在日時を基準にするため、テスト時は「本年」になる。
    func testParseSmartDate_WithShortDate_Future() {
        // 本日を基準に6月7日を推論する
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        // テスト用の月日を設定（現在の月+1 にすることで、確実に未来にする。12月の場合は翌年になるのを防ぐため適切な値を設定）
        let targetMonth = currentMonth == 12 ? 12 : currentMonth + 1
        let targetDay = 7
        
        // 未来の日付なので、年が今年（2026年など）になるはず。ただし、12月の場合は来年の1月なら未来だが、
        // 単純に currentMonth + 1 が13にならないように考慮する。
        let targetMonthStr = String(format: "%d", targetMonth)
        
        let elements = [
            OCRService.TextElement(text: "Test App", y: 0.1),
            OCRService.TextElement(text: "¥1,000", y: 0.2),
            OCRService.TextElement(text: "有効期限：\(targetMonthStr)月\(targetDay)日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        
        // 未来の日付として「今年」になっていることを確認
        let parsedYear = calendar.component(.year, from: item.nextPaymentDate)
        let expectedYear = (targetMonth < currentMonth) ? currentYear + 1 : currentYear
        
        XCTAssertEqual(parsedYear, expectedYear)
        XCTAssertEqual(calendar.component(.month, from: item.nextPaymentDate), targetMonth)
        XCTAssertEqual(calendar.component(.day, from: item.nextPaymentDate), targetDay)
    }
    
    /// 年が省略されている日付で、今日より前の月日（例: 「2月15日」など既に過ぎている日付）のスマート推論テスト
    /// 既に過ぎているため、「翌年」に推論されることを確認する。
    func testParseSmartDate_WithShortDate_Past() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        // 確実に「過去」の月日を設定（現在の月-1にする。1月の場合は前年の12月に設定）
        let targetMonth = currentMonth == 1 ? 12 : currentMonth - 1
        let targetDay = 15
        
        let targetMonthStr = String(format: "%d", targetMonth)
        
        let elements = [
            OCRService.TextElement(text: "Test App", y: 0.1),
            OCRService.TextElement(text: "¥1,000", y: 0.2),
            OCRService.TextElement(text: "有効期限：\(targetMonthStr)月\(targetDay)日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        
        // 過去の日付なので「翌年」（または今年1月で現在12月なら、月が小さいため翌年になる）に自動補完される
        let parsedYear = calendar.component(.year, from: item.nextPaymentDate)
        let expectedYear = (targetMonth < currentMonth) ? currentYear + 1 : currentYear
        
        XCTAssertEqual(parsedYear, expectedYear)
        XCTAssertEqual(calendar.component(.month, from: item.nextPaymentDate), targetMonth)
        XCTAssertEqual(calendar.component(.day, from: item.nextPaymentDate), targetDay)
    }
    
    // MARK: - Card Segmentation Tests
    
    /// 複数カード（ブロック）の一括セグメント分割の正当性テスト
    func testParseBulkSubscriptionInfo_MultipleCards() {
        let elements = [
            // Block 1
            OCRService.TextElement(text: "Apple Developer", y: 0.1),
            OCRService.TextElement(text: "Apple Developer Program", y: 0.15),
            OCRService.TextElement(text: "¥12,800", y: 0.2),
            OCRService.TextElement(text: "更新日：2027年5月19日", y: 0.25),
            
            // Block 2
            OCRService.TextElement(text: "ABEMA", y: 0.4),
            OCRService.TextElement(text: "プレミアムプラン", y: 0.45),
            OCRService.TextElement(text: "有効期限：6月7日", y: 0.5),
            
            // Block 3
            OCRService.TextElement(text: "Claude", y: 0.7),
            OCRService.TextElement(text: "Pro", y: 0.75),
            OCRService.TextElement(text: "¥3,000", y: 0.8),
            OCRService.TextElement(text: "更新予定：8月30日", y: 0.85)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        // 3つの異なるカードが抽出されることを確認
        XCTAssertEqual(result.count, 3)
        
        // Apple Developer の検証
        let item1 = result[0]
        XCTAssertTrue(item1.name.contains("Apple Developer"))
        XCTAssertEqual(item1.amount, 12800)
        XCTAssertEqual(item1.billingCycle, .yearly)
        
        // ABEMA の検証（金額なし ➡️ プリセット連携補完）
        let item2 = result[1]
        XCTAssertTrue(item2.name.contains("ABEMA"))
        XCTAssertEqual(item2.amount, 960) // プリセットの金額が補完されるはず
        XCTAssertEqual(item2.billingCycle, .monthly)
        XCTAssertTrue(item2.isAmountEstimated) // 推測フラグがON
        
        // Claude の検証
        let item3 = result[2]
        XCTAssertTrue(item3.name.contains("Claude"))
        XCTAssertEqual(item3.amount, 3000)
        XCTAssertEqual(item3.billingCycle, .monthly)
    }
    
    // MARK: - Amount & Billing Cycle Inference Tests
    
    /// 5000円以上なら年払いに自動推論するテスト
    func testBillingCycleInference_LargeAmountIsYearly() {
        let elements = [
            OCRService.TextElement(text: "Adobe Creative Cloud", y: 0.1),
            OCRService.TextElement(text: "¥72,800", y: 0.2),
            OCRService.TextElement(text: "更新日：2027年12月31日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        XCTAssertEqual(item.billingCycle, .yearly)
    }
    
    /// キーワード "年" があれば金額に関わらず年払いに自動推論するテスト
    func testBillingCycleInference_KeywordYearly() {
        let elements = [
            OCRService.TextElement(text: "Cheap App (年払い)", y: 0.1),
            OCRService.TextElement(text: "¥1,200", y: 0.2),
            OCRService.TextElement(text: "更新日：2027年12月31日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        XCTAssertEqual(item.billingCycle, .yearly)
    }
    
    /// プリセット登録のない未知のサービスで金額が検出できない場合、¥0 & 推測フラグONになるテスト
    func testUnknownService_NoAmount() {
        let elements = [
            OCRService.TextElement(text: "Super Mystic Widget App", y: 0.1),
            OCRService.TextElement(text: "有効期間：2027年12月31日", y: 0.3)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        XCTAssertEqual(item.name, "Super Mystic Widget App")
        XCTAssertEqual(item.amount, 0)
        XCTAssertEqual(item.billingCycle, .monthly)
        XCTAssertTrue(item.isAmountEstimated)
    }
    
    /// 解約済みフラグ (isCancelled) の自動検出テスト
    func testCancelledStatusDetection() {
        // 有効期限 => isCancelled = true
        let elements1 = [
            OCRService.TextElement(text: "Cancelled App A", y: 0.1),
            OCRService.TextElement(text: "有効期限：2027年12月31日", y: 0.3)
        ]
        let result1 = ocrService.parseBulkSubscriptionInfo(from: elements1)
        XCTAssertEqual(result1.count, 1)
        XCTAssertTrue(result1[0].isCancelled)
        
        // 有効期間 => isCancelled = true
        let elements2 = [
            OCRService.TextElement(text: "Cancelled App B", y: 0.1),
            OCRService.TextElement(text: "有効期間：2027年12月31日", y: 0.3)
        ]
        let result2 = ocrService.parseBulkSubscriptionInfo(from: elements2)
        XCTAssertEqual(result2.count, 1)
        XCTAssertTrue(result2[0].isCancelled)
        
        // 更新日 => isCancelled = false
        let elements3 = [
            OCRService.TextElement(text: "Active App A", y: 0.1),
            OCRService.TextElement(text: "更新日：2027年12月31日", y: 0.3)
        ]
        let result3 = ocrService.parseBulkSubscriptionInfo(from: elements3)
        XCTAssertEqual(result3.count, 1)
        XCTAssertFalse(result3[0].isCancelled)
        
        // 更新予定 => isCancelled = false
        let elements4 = [
            OCRService.TextElement(text: "Active App B", y: 0.1),
            OCRService.TextElement(text: "更新予定：2027年12月31日", y: 0.3)
        ]
        let result4 = ocrService.parseBulkSubscriptionInfo(from: elements4)
        XCTAssertEqual(result4.count, 1)
        XCTAssertFalse(result4[0].isCancelled)
    }
    
    /// スクショの最上部にステータスバー表示 (例: "11:53")、戻るボタン記号 (例: "< _")、navigation header ("Apple Account", "有効") が混入した場合でも、
    /// 正しく最初のカードのサービス名（例: "ABEMA"）を抽出できることをテストする
    func testParseBulkSubscriptionInfo_WithStatusBarAndHeaderNoise() {
        let elements = [
            OCRService.TextElement(text: "11:53", y: 0.01), // ステータスバー時刻
            OCRService.TextElement(text: "< _", y: 0.03), // 戻るボタンのchevron記号ノイズ
            OCRService.TextElement(text: "Apple Account", y: 0.05), // ヘッダー
            OCRService.TextElement(text: "有効", y: 0.08), // セクションタイトル
            OCRService.TextElement(text: "ABEMA", y: 0.12), // 実際の最初のカードのサービス名
            OCRService.TextElement(text: "プレミアムプラン", y: 0.15),
            OCRService.TextElement(text: "有効期限：6月7日", y: 0.18)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 1)
        let item = result[0]
        XCTAssertEqual(item.name, "ABEMA プレミアム") // プリセット名に補正されることを期待
        XCTAssertEqual(item.amount, 960)
        XCTAssertEqual(item.billingCycle, .monthly)
        XCTAssertTrue(item.isCancelled)
    }
    
    // MARK: - Non-Apple Platforms & Generic Formats Tests
    
    /// Google Play や汎用的な他社アプリ画面を想定したパーステスト
    func testParseBulkSubscriptionInfo_NonAppleGooglePlay() {
        let elements = [
            OCRService.TextElement(text: "Google Play", y: 0.02), // ノイズワード
            OCRService.TextElement(text: "定期購入の管理", y: 0.05), // ノイズワード
            
            // Item 1: YouTube Premium (Google Play 日本語形式)
            OCRService.TextElement(text: "YouTube Premium", y: 0.12),
            OCRService.TextElement(text: "個人プラン", y: 0.14),
            OCRService.TextElement(text: "1,280円/月", y: 0.16),
            OCRService.TextElement(text: "次回のお支払い日: 2026/06/15", y: 0.18),
            
            // Item 2: Spotify (Google Play 英語/記号混在形式)
            OCRService.TextElement(text: "Spotify", y: 0.3),
            OCRService.TextElement(text: "Premium Individual", y: 0.32),
            OCRService.TextElement(text: "1,078 yen", y: 0.34),
            OCRService.TextElement(text: "次回の支払い: 2026-07-20", y: 0.36)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 2)
        
        // YouTube Premium の検証
        let item1 = result[0]
        XCTAssertEqual(item1.name, "YouTube Premium") // プリセット名にマッチ
        XCTAssertEqual(item1.amount, 12800) // 1,280円 (円記号補正されるか、または金額12800でテスト定義に合わせるか？テスト内の表記は「1,280円/月」なので 1280 になるはず。注意: 1,280円のカンマが除外され1280になる)
        // ※ 1,280円のパース結果は Decimal(1280)
        XCTAssertEqual(item1.amount, 1280)
        XCTAssertEqual(item1.billingCycle, .monthly)
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: item1.nextPaymentDate), 2026)
        XCTAssertEqual(calendar.component(.month, from: item1.nextPaymentDate), 6)
        XCTAssertEqual(calendar.component(.day, from: item1.nextPaymentDate), 15)
        
        // Spotify の検証 (金額 postfix "yen" とハイフン区切り日付 "2026-07-20" を正しく抽出)
        let item2 = result[1]
        XCTAssertEqual(item2.name, "Spotify")
        XCTAssertEqual(item2.amount, 1078)
        XCTAssertEqual(item2.billingCycle, .monthly)
        XCTAssertEqual(calendar.component(.year, from: item2.nextPaymentDate), 2026)
        XCTAssertEqual(calendar.component(.month, from: item2.nextPaymentDate), 7)
        XCTAssertEqual(calendar.component(.day, from: item2.nextPaymentDate), 20)
    }
    
    /// 英語表記の更新日（Renews Jun 20, 2026）や英語の解約済（Expires Dec 31）を想定したパーステスト
    func testParseBulkSubscriptionInfo_NonAppleEnglish() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        let elements = [
            // Item 1: Netflix (英語かつ年を含む)
            OCRService.TextElement(text: "Netflix", y: 0.1),
            OCRService.TextElement(text: "1,980 JPY", y: 0.15),
            OCRService.TextElement(text: "Renews June 20, 2026", y: 0.2),
            
            // Item 2: iCloud (英語かつ年が省略され、解約済み)
            OCRService.TextElement(text: "iCloud+", y: 0.4),
            OCRService.TextElement(text: "450", y: 0.45), // 単一数値行の金額
            OCRService.TextElement(text: "Expires December 31", y: 0.5)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        XCTAssertEqual(result.count, 2)
        
        // Netflix の検証
        let item1 = result[0]
        XCTAssertEqual(item1.name, "Netflix")
        XCTAssertEqual(item1.amount, 1980)
        XCTAssertEqual(item1.billingCycle, .monthly)
        XCTAssertFalse(item1.isCancelled)
        XCTAssertEqual(calendar.component(.year, from: item1.nextPaymentDate), 2026)
        XCTAssertEqual(calendar.component(.month, from: item1.nextPaymentDate), 6)
        XCTAssertEqual(calendar.component(.day, from: item1.nextPaymentDate), 20)
        
        // iCloud+ の検証
        let item2 = result[1]
        XCTAssertEqual(item2.name, "iCloud+")
        XCTAssertEqual(item2.amount, 450)
        XCTAssertEqual(item2.billingCycle, .monthly)
        XCTAssertTrue(item2.isCancelled) // Expires => 解約済み判定
        
        // December 31 は過去なら翌年、将来なら今年にスマート推論される
        let parsedYear = calendar.component(.year, from: item2.nextPaymentDate)
        let expectedYear = (12 < calendar.component(.month, from: now)) ? currentYear + 1 : currentYear
        XCTAssertEqual(parsedYear, expectedYear)
        XCTAssertEqual(calendar.component(.month, from: item2.nextPaymentDate), 12)
        XCTAssertEqual(calendar.component(.day, from: item2.nextPaymentDate), 31)
    }
    
    /// 日付セパレーターがない明細一覧のような画像を想定した、金額ギャップベースの自動ブロック分割（フォールバック）テスト
    func testParseBulkSubscriptionInfo_FallbackSegmentation() {
        let elements = [
            // Item 1: Netflix (日付キーワードなし、金額 ¥1,490 のみ)
            OCRService.TextElement(text: "Netflix", y: 0.1),
            OCRService.TextElement(text: "¥1,490", y: 0.15),
            OCRService.TextElement(text: "2026/06/10", y: 0.18), // 日付セパレーター文言なしの単独日付
            
            // Item 2: ChatGPT Plus (日付キーワードなし、金額 ¥3,000 のみ)
            OCRService.TextElement(text: "ChatGPT Plus", y: 0.3),
            OCRService.TextElement(text: "¥3,000", y: 0.35),
            OCRService.TextElement(text: "2026/06/15", y: 0.38)
        ]
        
        let result = ocrService.parseBulkSubscriptionInfo(from: elements)
        
        // 金額のギャップ（Y座標差 0.15）によって2枚のカードとして自動分割されることを確認
        XCTAssertEqual(result.count, 2)
        
        let item1 = result[0]
        XCTAssertEqual(item1.name, "Netflix")
        XCTAssertEqual(item1.amount, 1490)
        
        let item2 = result[1]
        XCTAssertEqual(item2.name, "ChatGPT Plus")
        XCTAssertEqual(item2.amount, 3000)
    }
}
