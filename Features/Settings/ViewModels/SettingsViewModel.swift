//
//  SettingsViewModel.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

@Observable
final class SettingsViewModel {
    
    /// サブスクリプション配列をCSV文字列に変換する
    func generateCSV(from subscriptions: [Subscription]) -> String {
        var csvString = "名前,金額,請求サイクル,カテゴリ,開始日,無料トライアル終了日,サブスク終了日,ステータス\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        for sub in subscriptions {
            // カンマを含む文字列はダブルクォーテーションで囲む
            let name = "\"\(sub.name.replacingOccurrences(of: "\"", with: "\"\""))\""
            let amount = NSDecimalNumber(decimal: sub.amount).stringValue
            let cycle = sub.billingCycle.displayName
            let category = sub.category.displayName
            let startDate = dateFormatter.string(from: sub.startDate)
            
            let trialEnd = sub.trialEndDate.map { dateFormatter.string(from: $0) } ?? "なし"
            let endDate = sub.endDate.map { dateFormatter.string(from: $0) } ?? "未定"
            
            let status = sub.isActive ? "アクティブ" : "解約済み"
            
            let row = [name, amount, cycle, category, startDate, trialEnd, endDate, status].joined(separator: ",")
            csvString += row + "\n"
        }
        
        return csvString
    }
}
