//
//  OnboardingView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// 初回起動時に表示されるチュートリアル（オンボーディング）画面
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    
    // 現在のページインデックス
    @State private var currentPage = 0
    
    var onComplete: (() -> Void)? = nil

    // チュートリアルのコンテンツ定義
    private let pages: [PageContent] = [
        PageContent(
            title: "毎月、いくら使っていますか？",
            description: "気がつけば増えているサブスク。使っていないサービスにお金を払い続けていませんか？\nSubsqManagerがあなたの無駄な出費をゼロにします。",
            systemImage: "questionmark.circle.fill",
            color: .blue
        ),
        PageContent(
            title: "すべてを一つの場所で",
            description: "「ダッシュボード」で毎月の合計額を把握し、「カレンダー」で直近の支払いをチェック。\n「分析」タブで支出の偏りを可視化します。",
            systemImage: "chart.bar.doc.horizontal",
            color: .green
        ),
        PageContent(
            title: "解約忘れを確実にブロック",
            description: "無料トライアルの終了や、設定した「終了予定日」の前日に通知でお知らせ。\n安心して新しいサービスを試せます。",
            systemImage: "bell.badge.fill",
            color: .orange
        ),
        PageContent(
            title: "さあ、管理を始めましょう！",
            description: "継続して利用することで、節約できる金額が目に見えてわかります。\nまずは右上の「＋ボタン」から、最初のサブスクを登録してみましょう！",
            systemImage: "plus.circle.fill",
            color: .purple
        )
    ]

    var body: some View {
        VStack {
            // メインのページコンテンツ（切り替えアニメーション付き）
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never)) // スワイプ可能にするがドットは自前で描画
            #endif
            
            // 下部のコントロール（戻る・ドット・次へ/はじめる）
            bottomControls
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - ページコンポーネント
    
    private func pageView(for page: PageContent) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(page.color.gradient)
                .padding(.bottom, 20)
            
            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 下部コントロール
    
    private var bottomControls: some View {
        HStack {
            // 戻るボタン
            Button {
                withAnimation {
                    if currentPage > 0 { currentPage -= 1 }
                }
            } label: {
                Text("戻る")
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
            }
            .opacity(currentPage == 0 ? 0 : 1) // 1ページ目は非表示だがレイアウトは維持
            
            Spacer()
            
            // ページインジケーター（ドット）
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            
            Spacer()
            
            // 次へ / はじめる ボタン
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "はじめる" : "次へ")
                    .fontWeight(.bold)
                    .foregroundStyle(currentPage == pages.count - 1 ? .white : .accentColor)
                    .frame(width: 80, height: 44, alignment: .center)
                    .background(currentPage == pages.count - 1 ? Color.accentColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - アクション
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        if let onComplete = onComplete {
            onComplete()
        } else {
            dismiss()
        }
    }
}

// ページデータをまとめる構造体
struct PageContent {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
}

#if !os(iOS)
// macOSでNSColorを使えるようにするためのエイリアス的な対応
import AppKit
#else
import UIKit
extension NSColor {
    static var windowBackgroundColor: UIColor { .systemBackground }
}
typealias NSColor = UIColor
#endif

#Preview {
    OnboardingView()
}
