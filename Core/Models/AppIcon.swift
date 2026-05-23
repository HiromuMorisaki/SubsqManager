//
//  AppIcon.swift
//  SubsqManager
//
//  Created by AI on 2026/05/22.
//

import Foundation
import UIKit

/// 切り替え可能なアプリアイコンの列挙型
enum AppIcon: String, CaseIterable, Identifiable {
    case `default`
    case neonPurple = "AppIcon-NeonPurple"
    case neonPink = "AppIcon-NeonPink"
    case neonBlue = "AppIcon-NeonBlue"
    case neonGreen = "AppIcon-NeonGreen"
    case cyberpunk = "AppIcon-Cyberpunk"
    case pureBlack = "AppIcon-PureBlack"
    case gold = "AppIcon-Gold"
    
    var id: String { self.rawValue }
    
    /// UIに表示するアイコン名
    var displayName: String {
        switch self {
        case .default: return "デフォルト"
        case .neonPurple: return "ネオンパープル"
        case .neonPink: return "ネオンピンク"
        case .neonBlue: return "ネオンブルー"
        case .neonGreen: return "ネオングリーン"
        case .cyberpunk: return "サイバーパンク"
        case .pureBlack: return "ピュアブラック"
        case .gold: return "ゴールド"
        }
    }
    
    /// アイコンを変更するメソッド
    func apply() {
        let targetIconName = self == .default ? nil : self.rawValue
        
        // すでに現在のアイコンと同じなら何もしない
        guard UIApplication.shared.alternateIconName != targetIconName else { return }
        
        UIApplication.shared.setAlternateIconName(targetIconName) { error in
            if let error = error {
                print("Failed to change app icon: \(error.localizedDescription)")
            } else {
                print("App icon changed successfully to \(self.displayName)")
            }
        }
    }
    
    /// 現在のアイコン設定を取得する
    static var current: AppIcon {
        if let alternateIconName = UIApplication.shared.alternateIconName,
           let icon = AppIcon(rawValue: alternateIconName) {
            return icon
        }
        return .default
    }
}
