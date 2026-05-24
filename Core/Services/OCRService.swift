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

/// Visionフレームワークを用いて画像からテキストを抽出し、サブスク情報を推論するサービス
final class OCRService {
    
    /// 画像データからテキストを抽出する
    /// - Parameter imageData: 対象の画像データ（スクリーンショットやレシートなど）
    /// - Returns: 認識された文字列行の配列
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
                
                // 信頼度の高い候補のみを抽出
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings)
            }
            
            // 日本語と英語を高精度で認識
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
    
    /// 抽出されたテキスト行の配列から、サブスクの情報を推論する
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
            // プリセット名の一部（3文字以上の単語）が含まれているか、特例（Amazon Prime -> プライム）
            let words = presetLower.components(separatedBy: " ").filter { $0.count >= 3 }
            let hasKeywordMatch = lowercasedText.contains(presetLower) || 
                                  words.contains(where: { lowercasedText.contains($0) }) || 
                                  (presetLower == "amazon prime" && lowercasedText.contains("プライム"))
            
            if hasKeywordMatch {
                // 抽出された金額が、このプリセットのプラン金額に存在するか？
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
            
            // サービス名だけでも当てに行く
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
}
