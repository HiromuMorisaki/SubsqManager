//
//  AppTheme.swift
//  SubsqManager
//
//  Created by AI on 2026/05/22.
//

import SwiftUI

/// アプリ全体で利用するテーマ（アクセントカラー）の列挙型
enum AppTheme: String, CaseIterable, Identifiable {
    case neonPurple
    case neonPink
    case neonBlue
    case neonGreen
    case cyberpunkYellow
    
    var id: String { self.rawValue }
    
    /// UIに表示するテーマ名
    var displayName: String {
        switch self {
        case .neonPurple: return "ネオンパープル"
        case .neonPink: return "ネオンピンク"
        case .neonBlue: return "ネオンブルー"
        case .neonGreen: return "ネオングリーン"
        case .cyberpunkYellow: return "サイバーパンク"
        }
    }
    
    /// テーマのアクセントカラー
    var color: Color {
        switch self {
        case .neonPurple: return .purple
        case .neonPink: return .pink
        case .neonBlue: return .blue
        case .neonGreen: return .green
        case .cyberpunkYellow: return Color(red: 1.0, green: 0.8, blue: 0.0) // 明るいイエロー
        }
    }
    
    /// ダッシュボード等で用いるグラデーションの開始色・終了色
    var gradientColors: [Color] {
        switch self {
        case .neonPurple: return [.purple.opacity(0.85), .indigo.opacity(0.9)]
        case .neonPink: return [.pink.opacity(0.85), .red.opacity(0.9)]
        case .neonBlue: return [.blue.opacity(0.85), .cyan.opacity(0.9)]
        case .neonGreen: return [.green.opacity(0.85), .teal.opacity(0.9)]
        case .cyberpunkYellow: return [Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.85), Color.orange.opacity(0.9)]
        }
    }
}
