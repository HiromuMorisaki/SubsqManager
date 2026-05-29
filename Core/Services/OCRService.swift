//
//  OCRService.swift
//  SubsqManager
//

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// OCR関連のカスタムエラー
enum OCRServiceError: Error {
    case invalidImage
    case recognitionFailed
}

/// スクショから一括検知された個別のサブスク情報構造体（一括インポーター用）
struct ParsedBulkItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: Decimal
    var billingCycle: BillingCycle
    var nextPaymentDate: Date
    var iconName: String
    var category: Category
    
    /// 金額が自動検知できずにプリセットから推測した、または ¥0 になった場合のフラグ
    var isAmountEstimated: Bool
    
    /// すでに解約済み（有効期限・有効期間と表記されている）かどうかのフラグ
    var isCancelled: Bool
    
    /// 無料トライアル中かどうか
    var hasTrial: Bool
    
    /// 無料トライアル終了日
    var trialEndDate: Date
    
    /// 満足度（1〜5段階、デフォルト3）
    var satisfaction: Int
    
    init(
        name: String,
        amount: Decimal,
        billingCycle: BillingCycle,
        nextPaymentDate: Date,
        iconName: String,
        category: Category = .other,
        isAmountEstimated: Bool,
        isCancelled: Bool,
        hasTrial: Bool = false,
        trialEndDate: Date = Date().addingTimeInterval(86400 * 14),
        satisfaction: Int = 3
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.nextPaymentDate = nextPaymentDate
        self.iconName = iconName
        self.category = category
        self.isAmountEstimated = isAmountEstimated
        self.isCancelled = isCancelled
        self.hasTrial = hasTrial
        self.trialEndDate = trialEndDate
        self.satisfaction = satisfaction
    }
}

/// Visionフレームワークを用いて画像からテキストを抽出し、サブスク情報を推論するサービス
final class OCRService {
    
    /// 位置情報付きのテキスト要素構造体
    struct TextElement {
        let text: String
        let y: CGFloat // 画像上部からの相対的なY座標 (0.0 = 最上部, 1.0 = 最下部)
    }
    
    /// 画像データからテキストを抽出する（従来のフラット配列）
    func extractText(from imageData: Data) async throws -> [String] {
        guard let cgImage = createCGImage(from: imageData) else {
            throw OCRServiceError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings)
            }
            
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 画像データからテキストとその縦位置（Y座標）を取得し、上から順にソートして返す
    func extractTextWithPositions(from imageData: Data) async throws -> [TextElement] {
        guard let cgImage = createCGImage(from: imageData) else {
            throw OCRServiceError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let elements = observations.compactMap { observation -> TextElement? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    // Y座標は上からの距離にする (1.0 - y)
                    let yPos = 1.0 - observation.boundingBox.origin.y
                    return TextElement(text: topCandidate.string, y: yPos)
                }
                
                // Y座標でソート（上から下へ）
                let sortedElements = elements.sorted { $0.y < $1.y }
                continuation.resume(returning: sortedElements)
            }
            
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// UIImage や Data から CGImage を生成するヘルパー
    private func createCGImage(from data: Data) -> CGImage? {
        #if canImport(UIKit)
        return UIImage(data: data)?.cgImage
        #else
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
        #endif
    }
    
    /// 抽出されたテキスト行の配列から、サブスクの情報を推論する（単一パース用）
    func parseSubscriptionInfo(from textLines: [String]) -> (name: String?, amount: Decimal?, billingCycle: BillingCycle?) {
        let fullText = textLines.joined(separator: " ")
        let lowercasedText = fullText.lowercased()
        
        var parsedName: String?
        var parsedAmount: Decimal?
        var parsedCycle: BillingCycle?
        
        // 1. 金額の抽出（すべての候補を上から順に抽出）
        var extractedAmounts: [Decimal] = []
        let amountPattern = "(?:¥|￥|JPY)\\s*([0-9,]+)|([0-9,]+)\\s*(?:円|yen|JPY)"
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText))
            
            for match in matches {
                if let range1 = Range(match.range(at: 1), in: fullText) {
                    let numStr = String(fullText[range1]).replacingOccurrences(of: ",", with: "")
                    if let decimal = Decimal(string: numStr), decimal > 0 {
                        extractedAmounts.append(decimal)
                    }
                } else if let range2 = Range(match.range(at: 2), in: fullText) {
                    let numStr = String(fullText[range2]).replacingOccurrences(of: ",", with: "")
                    if let decimal = Decimal(string: numStr), decimal > 0 {
                        extractedAmounts.append(decimal)
                    }
                }
            }
        }
        
        // 正規表現で見つからなかった場合等のための単独行数字の抽出
        for line in textLines {
            let cleanLine = line.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let decimal = Decimal(string: cleanLine), decimal >= 100 {
                if !extractedAmounts.contains(decimal) { // 重複排除
                    extractedAmounts.append(decimal)
                }
            }
        }
        
        // 2. 支払い周期と金額のスマート照合 (Preset Matching)
        var isSmartMatched = false
        for preset in SubscriptionPreset.defaultPresets {
            let presetLower = preset.name.lowercased()
            let words = presetLower.components(separatedBy: " ").filter { $0.count >= 3 }
            let hasKeywordMatch = lowercasedText.contains(presetLower) || 
                                  words.contains(where: { lowercasedText.contains($0) }) || 
                                  (presetLower == "amazon prime" && lowercasedText.contains("プライム"))
            
            if hasKeywordMatch {
                for amount in extractedAmounts {
                    if let matchedPlan = preset.plans.first(where: { Decimal(string: "\($0.amount)") == amount }) {
                        parsedName = preset.name
                        parsedAmount = amount
                        parsedCycle = matchedPlan.billingCycle
                        isSmartMatched = true
                        break
                    }
                }
            }
            if isSmartMatched { break }
        }
        
        // 3. スマート照合できなかった場合のフォールバック（従来の推測）
        if !isSmartMatched {
            parsedAmount = extractedAmounts.first
            
            for preset in SubscriptionPreset.defaultPresets {
                if lowercasedText.contains(preset.name.lowercased()) {
                    parsedName = preset.name
                    break
                }
            }
            
            if lowercasedText.contains("年額") || lowercasedText.contains("年払") || lowercasedText.contains("yearly") || lowercasedText.contains("annual") || lowercasedText.contains("1年") {
                parsedCycle = .yearly
            } else if lowercasedText.contains("月額") || lowercasedText.contains("月払") || lowercasedText.contains("monthly") || lowercasedText.contains("1ヶ月") || lowercasedText.contains("1月") {
                parsedCycle = .monthly
            }
        }
        
        return (parsedName, parsedAmount, parsedCycle)
    }
    
    // MARK: - 一括スクショインポーター解析コアロジック
    
    /// スクショのテキスト要素群から、複数のカード情報を自動セグメント分割し、一括で解析・抽出する。
    func parseBulkSubscriptionInfo(from elements: [TextElement]) -> [ParsedBulkItem] {
        var items: [ParsedBulkItem] = []
        var currentBlock: [TextElement] = []
        
        // Apple以外（Google Play、クレジットカード明細、家計簿等）の多様な日付表記セパレーターに対応
        let dateKeywords = [
            "更新日", "有効期限", "更新予定", "有効期間", "有効期間終了日",
            "次回支払い", "次回の支払い", "次回のお支払い", "次回お支払い", "お支払い日", "お支払日", "支払日",
            "契約更新", "期限", "終了日", "次の決済", "決済日", "引き落とし日", "次回請求", "請求日",
            "Renews", "Next payment", "Next bill", "Expires", "Renewal date", "Billing date", "Next billing", "Billing period"
        ]
        
        // 通貨記号や金額を検出するパターン
        let amountPattern = "(?:¥|￥|JPY)\\s*([0-9,]+)|([0-9,]+)\\s*(?:円|yen|JPY)"
        
        for element in elements {
            let text = element.text
            
            // 1. 日付セパレーターを検出したか
            let hasSeparator = dateKeywords.contains { text.localizedCaseInsensitiveContains($0) }
            
            // 2. 金額要素を検出したか
            let isAmount = text.range(of: amountPattern, options: .regularExpression) != nil
            
            // ブロック内にすでに金額が含まれているかチェック
            let currentBlockHasAmount = currentBlock.contains { 
                $0.text.range(of: amountPattern, options: .regularExpression) != nil 
            }
            
            // 直前の要素とのY座標差 (同じカード内かどうかの判定用)
            let lastY = currentBlock.last?.y ?? element.y
            let yGap = element.y - lastY
            
            // セパレーターが検出された、または「すでに金額が含まれているブロックに新しい金額が一定以上のY座標ギャップ(0.06以上)をあけて出現した」場合
            // これにより、日付セパレーターがない明細等の画面でも、金額の境界線をもとに正しく個別カードとして分割できます。
            if hasSeparator || (isAmount && currentBlockHasAmount && yGap >= 0.06) {
                if hasSeparator {
                    currentBlock.append(element) // セパレーター自体を含める
                }
                
                if let parsedItem = parseSingleCardBlock(currentBlock) {
                    items.append(parsedItem)
                }
                
                currentBlock.removeAll()
                
                if !hasSeparator {
                    // 金額での分割の場合、現在の金額要素は次の新しいブロックの先頭にする
                    currentBlock.append(element)
                }
            } else {
                currentBlock.append(element)
            }
        }
        
        // 残ったブロックがあれば最後に解析
        if !currentBlock.isEmpty {
            if let parsedItem = parseSingleCardBlock(currentBlock) {
                items.append(parsedItem)
            }
        }
        
        return items
    }
    
    /// サービス名として有効なテキストかどうかを判定する（時間、電池残量、システム表示、ナビゲーションヘッダー等を除外）
    private func isValidServiceName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        
        // 文字列がアルファベット、日本語、または数字を1文字も含まない場合（記号や記号の組み合わせ "< _" などのノイズ）を除外
        let lettersAndDigits = CharacterSet.letters.union(.decimalDigits)
        if trimmed.rangeOfCharacter(from: lettersAndDigits) == nil {
            return false
        }
        
        // システム表示、ヘッダー、メニューボタンなどの除外リスト（Google Playや明細、メール等にも対応）
        let blacklist = [
            "サブスクリプション", "有効", "Apple Account", "サインアウト", "キャンセル", "完了", "編集", "アカウント",
            "account.apple.com", "サインイン", "有効期限", "有効期間", "更新日", "更新予定", "定期購入", "管理",
            "Google Play", "メニュー", "詳細", "Manage", "Subscription", "決済", "明細", "履歴", "合計", "利用明細",
            "クレジットカード", "請求", "お支払い", "支払い", "次回支払い", "次回の支払い", "次回のお支払い", "お支払方法",
            "登録中", "プラン", "料金", "金額", "価格", "設定", "ホーム", "一覧", "次へ", "戻る", "確認", "購入", "購入履歴",
            "閉じる", "購入手続き", "決済日", "支払日", "決済方法", "ステータス", "ご利用明細", "領収書", "メール", "配信",
            "並べ替え", "並び替え", "オプション", "表示", "すべて"
        ]
        if blacklist.contains(where: { trimmed.localizedCaseInsensitiveCompare($0) == .orderedSame || trimmed.contains($0) }) {
            return false
        }
        
        // 時刻表示 (例: "11:53" や "9:41" や "23:59") を正規表現で除外
        let timePattern = "^[0-9]{1,2}:[0-9]{2}$"
        if let regex = try? NSRegularExpression(pattern: timePattern),
           regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
            return false
        }
        
        // パーセンテージ表示 (例: "100%" や "80%") を除外
        if trimmed.hasSuffix("%") {
            let numPart = trimmed.dropLast().trimmingCharacters(in: .whitespaces)
            if Int(numPart) != nil {
                return false
            }
        }
        
        // 数値単体 (例: "2026" や "7") を除外
        if Int(trimmed) != nil {
            return false
        }
        
        return true
    }
    
    /// 月名の英語表記（短縮形・フルスペル）を数値に変換する
    private func parseEnglishMonth(_ text: String) -> Int? {
        let months = [
            "jan": 1, "january": 1,
            "feb": 2, "february": 2,
            "mar": 3, "march": 3,
            "apr": 4, "april": 4,
            "may": 5,
            "jun": 6, "june": 6,
            "jul": 7, "july": 7,
            "aug": 8, "august": 8,
            "sep": 9, "september": 9, "sept": 9,
            "oct": 10, "october": 10,
            "nov": 11, "november": 11,
            "dec": 12, "december": 12
        ]
        let lower = text.lowercased()
        for (key, val) in months {
            if lower.contains(key) {
                return val
            }
        }
        return nil
    }
    
    /// 単一カードブロック of text elementsから、サービス名、金額、次回請求日、周期を解析する
    private func parseSingleCardBlock(_ block: [TextElement]) -> ParsedBulkItem? {
        // カード内に十分な情報がない場合はスキップ
        guard block.count >= 2 else { return nil }
        
        let dateKeywords = [
            "更新日", "有効期限", "更新予定", "有効期間", "有効期間終了日",
            "次回支払い", "次回の支払い", "次回のお支払い", "次回お支払い", "お支払い日", "お支払日", "支払日",
            "契約更新", "期限", "終了日", "次の決済", "決済日", "引き落とし日", "次回請求", "請求日",
            "Renews", "Next payment", "Next bill", "Expires", "Renewal date", "Billing date", "Next billing", "Billing period"
        ]
        
        // 先にセパレーター（日付表示）のY座標を取得する
        var separatorElement: TextElement?
        for element in block {
            let t = element.text
            if dateKeywords.contains(where: { t.localizedCaseInsensitiveContains($0) }) {
                separatorElement = element
                break
            }
        }
        
        let separatorY = separatorElement?.y ?? 1.0
        
        // 1. サービス名（ブロック内の最初の有効なサービス名テキスト）
        var serviceNameElement: TextElement?
        for element in block {
            // Y座標の差が 0.15 以内（同じカード内）の要素のみを対象とする
            if separatorY - element.y <= 0.15 {
                if isValidServiceName(element.text) {
                    serviceNameElement = element
                    break
                }
            }
        }
        
        guard let nameElement = serviceNameElement else {
            return nil
        }
        let rawName = nameElement.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // プリセットデータベースで正規化された名前があれば補正
        var matchedPreset: SubscriptionPreset? = nil
        var finalName = rawName
        
        for preset in SubscriptionPreset.defaultPresets {
            if rawName.localizedCaseInsensitiveContains(preset.name) || 
               preset.name.localizedCaseInsensitiveContains(rawName) {
                matchedPreset = preset
                finalName = preset.name
                break
            }
        }
        
        // 2. 金額の抽出（通貨記号あり、なし、後方一致パターン等に幅広く対応）
        var amount: Decimal? = nil
        let amountPatterns = [
            "(?:¥|￥|JPY)\\s*([0-9,]+)",               // 前方一致: ¥1,000, ￥980
            "([0-9,]+)\\s*(?:円|yen|JPY)",             // 後方一致: 1000円, 980 yen
            "^[0-9,]{3,6}$"                           // 3〜6桁の純粋な数値単体行: 980, 1080
        ]
        
        for element in block {
            let t = element.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for pattern in amountPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    if let match = regex.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)) {
                        // キャプチャグループ（括弧）がある場合はそれを、ない場合は全体を使用
                        let targetRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
                        if let range = Range(targetRange, in: t) {
                            let numStr = String(t[range]).replacingOccurrences(of: ",", with: "")
                            if let dec = Decimal(string: numStr), dec > 0 {
                                amount = dec
                                break
                            }
                        }
                    }
                }
            }
            if amount != nil { break }
        }
        
        // 3. 請求日のパースと「年」のスマート推論
        var paymentDate = Date()
        var dateText = ""
        
        for element in block {
            let t = element.text
            if dateKeywords.contains(where: { t.localizedCaseInsensitiveContains($0) }) {
                dateText = t
                break
            }
        }
        
        // 日付セパレーター文言が見つからなかった場合、ブロック内にある適当な日付パターンの文字列から抽出
        if dateText.isEmpty {
            let fallbackDatePattern = "(?:[0-9]{2,4}[年\\.\\/-][0-9]{1,2}[月\\.\\/-][0-9]{1,2}|[0-9]{1,2}[月\\.\\/-][0-9]{1,2})"
            for element in block {
                let t = element.text
                if t.range(of: fallbackDatePattern, options: .regularExpression) != nil {
                    dateText = t
                    break
                }
            }
        }
        
        if !dateText.isEmpty {
            paymentDate = parseSmartDate(from: dateText)
        }
        
        // 4. 周期の推論と金額の自動推測（プリセットマッチング）
        var cycle: BillingCycle = .monthly
        var isAmountEstimated = false
        
        // ブロック内のプラン名などに "annual" "年" "年額" "1年" "yearly" 等があれば年払に
        let fullBlockText = block.map { $0.text }.joined(separator: " ").lowercased()
        if fullBlockText.contains("年") || fullBlockText.contains("yearly") || fullBlockText.contains("annual") {
            cycle = .yearly
        }
        
        if let amt = amount {
            amount = amt
            if amt >= 5000 {
                // 5,000円を超えるような場合は年額プランである可能性が高い
                cycle = .yearly
            }
        } else {
            isAmountEstimated = true
            if let preset = matchedPreset, let firstPlan = preset.plans.first {
                amount = firstPlan.amount
                cycle = firstPlan.billingCycle
            } else {
                amount = 0
                cycle = .monthly
            }
        }
        
        let icon = matchedPreset?.iconName ?? "creditcard"
        let category = matchedPreset?.category ?? .other
        
        // すでに解約済みかどうかの判定（キーワード拡張）
        let cancelKeywords = ["有効期限", "有効期間", "終了日", "期限切れ", "キャンセル済み", "Expires", "Cancelled"]
        let isCancelled = cancelKeywords.contains { dateText.localizedCaseInsensitiveContains($0) }
        
        return ParsedBulkItem(
            name: finalName,
            amount: amount ?? 0,
            billingCycle: cycle,
            nextPaymentDate: paymentDate,
            iconName: icon,
            category: category,
            isAmountEstimated: isAmountEstimated,
            isCancelled: isCancelled
        )
    }
    
    /// 「有効期限：6月7日」や「更新日：2027年5月19日」といった日付表現から Date をスマート解析する。
    /// 年が省略されている場合は、現在日時を基準に自動推論して補完する。
    private func parseSmartDate(from text: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        var year: Int? = nil
        var month: Int = calendar.component(.month, from: now)
        var day: Int = calendar.component(.day, from: now)
        
        // パターンA: 2027年5月19日、2026/06/15、26-5-19、2026.05.28 (年を含む日本語/記号区切り形式)
        let fullDatePattern = "([0-9]{2,4})[年\\.\\/-]([0-9]{1,2})[月\\.\\/-]([0-9]{1,2})日?"
        
        // パターンB: 英語の日付表現 (例: "Jun 20, 2026" や "20 Jun 2026" や "June 20")
        let englishDatePattern = "([a-zA-Z]{3,9})\\s*([0-9]{1,2})(?:st|nd|rd|th)?\\s*,?\\s*([0-9]{4})?"
        
        // パターンC: 6月7日 または 06/07 (年が省略されている日本語/記号区切り形式)
        let shortDatePattern = "([0-9]{1,2})[月\\.\\/-]([0-9]{1,2})日?"
        
        if let regex = try? NSRegularExpression(pattern: fullDatePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            if let yRange = Range(match.range(at: 1), in: text),
               let mRange = Range(match.range(at: 2), in: text),
               let dRange = Range(match.range(at: 3), in: text) {
                
                let yVal = Int(text[yRange]) ?? currentYear
                year = yVal < 100 ? yVal + 2000 : yVal // 2桁表記(26年)への対応
                month = Int(text[mRange]) ?? month
                day = Int(text[dRange]) ?? day
            }
        }
        else if let regex = try? NSRegularExpression(pattern: englishDatePattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            if let mRange = Range(match.range(at: 1), in: text),
               let dRange = Range(match.range(at: 2), in: text) {
                
                let monthStr = String(text[mRange])
                if let mVal = parseEnglishMonth(monthStr) {
                    month = mVal
                    day = Int(text[dRange]) ?? day
                    
                    if match.numberOfRanges > 3, let yRange = Range(match.range(at: 3), in: text), !yRange.isEmpty {
                        year = Int(text[yRange])
                    } else {
                        // 年が省略されている場合はスマート推論
                        var comp = DateComponents()
                        comp.year = currentYear
                        comp.month = month
                        comp.day = day
                        if let parsedThisYear = calendar.date(from: comp) {
                            year = parsedThisYear >= now ? currentYear : currentYear + 1
                        }
                    }
                }
            }
        }
        else if let regex = try? NSRegularExpression(pattern: shortDatePattern, options: .caseInsensitive),
                let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            if let mRange = Range(match.range(at: 1), in: text),
               let dRange = Range(match.range(at: 2), in: text) {
                
                month = Int(text[mRange]) ?? month
                day = Int(text[dRange]) ?? day
                
                // 【スマート推論】
                // 抽出された月日と本日を比較し、既に過ぎている月日なら「翌年」、将来の月日なら「今年」と判定する。
                var comp = DateComponents()
                comp.year = currentYear
                comp.month = month
                comp.day = day
                
                if let parsedThisYear = calendar.date(from: comp) {
                    if parsedThisYear >= now {
                        year = currentYear
                    } else {
                        year = currentYear + 1
                    }
                }
            }
        }
        
        var targetComp = DateComponents()
        targetComp.year = year ?? currentYear
        targetComp.month = month
        targetComp.day = day
        targetComp.hour = 9
        targetComp.minute = 0
        targetComp.second = 0
        
        return calendar.date(from: targetComp) ?? now
    }
}
