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
        
        // 1. 金額の抽出
        // 例: "¥ 1,590", "1590円", "1,500 JPY"
        let amountPattern = "(?:¥|￥|JPY)\\s*([0-9,]+)|([0-9,]+)\\s*(?:円|yen|JPY)"
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText))
            
            for match in matches {
                if let range1 = Range(match.range(at: 1), in: fullText) {
                    let numStr = String(fullText[range1]).replacingOccurrences(of: ",", with: "")
                    if let decimal = Decimal(string: numStr), decimal > 0 {
                        parsedAmount = decimal
                        break
                    }
                } else if let range2 = Range(match.range(at: 2), in: fullText) {
                    let numStr = String(fullText[range2]).replacingOccurrences(of: ",", with: "")
                    if let decimal = Decimal(string: numStr), decimal > 0 {
                        parsedAmount = decimal
                        break
                    }
                }
            }
        }
        
        // もし正規表現で見つからなかった場合、単独の数字行からも推測（100以上であれば金額と見なす等のヒューリスティクス）
        if parsedAmount == nil {
            for line in textLines {
                let cleanLine = line.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let decimal = Decimal(string: cleanLine), decimal >= 100 {
                    parsedAmount = decimal
                    break
                }
            }
        }
        
        // 2. 支払い周期の抽出
        if lowercasedText.contains("年額") || lowercasedText.contains("年払") || lowercasedText.contains("yearly") || lowercasedText.contains("annual") || lowercasedText.contains("1年") {
            parsedCycle = .yearly
        } else if lowercasedText.contains("月額") || lowercasedText.contains("月払") || lowercasedText.contains("monthly") || lowercasedText.contains("1ヶ月") || lowercasedText.contains("1月") {
            parsedCycle = .monthly
        }
        
        // 3. サービス名の抽出 (プリセットとの照合)
        // SubscriptionPreset.defaultPresets にある名前がテキストに含まれていれば採用
        for preset in SubscriptionPreset.defaultPresets {
            if lowercasedText.contains(preset.name.lowercased()) {
                parsedName = preset.name
                break
            }
        }
        
        return (parsedName, parsedAmount, parsedCycle)
    }
}
