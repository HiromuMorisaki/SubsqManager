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

    private let pages: [PageContent] = [
        PageContent(
            title: "お得のつもりが“払い損”に？",
            description: "「初月無料だから」と登録し、解約を忘れて引き落とされ続けていませんか？\nコテサクなら、忘れていたサブスクや不要な課金を可視化し、無駄な出費を完全にゼロにします。",
            systemImage: "sparkles",
            color: .blue
        ),
        PageContent(
            title: "すべてを一つの場所で",
            description: "月々の支払いをダッシュボードで一目で把握。\nカレンダーで直近の支払いをチェックし、分析タブで支出の偏りを可視化します。",
            systemImage: "chart.bar.doc.horizontal",
            color: .green
        ),
        PageContent(
            title: "解約忘れを確実にブロック",
            description: "無料トライアルの終了や、設定した終了予定日の前日に通知でしっかりとお知らせ。\n安心して新しいサービスを試せます。",
            systemImage: "bell.badge.fill",
            color: .orange
        ),
        PageContent(
            title: "さあ、未来を変えましょう",
            description: "1つのサブスクを見直すだけで、年間数万円の節約に。\nコテサクと一緒に、賢く無駄のない生活をスタートしましょう！",
            systemImage: "arrow.up.forward.app.fill",
            color: .purple
        )
    ]

    var body: some View {
        ZStack {
            // プレミアムなモーフィング背景 (ページのテーマカラーに合わせたソフトグラデーション)
            ZStack {
                Color(NSColor.windowBackgroundColor)
                
                RadialGradient(
                    colors: [
                        pages[currentPage].color.opacity(0.12),
                        pages[currentPage].color.opacity(0.02),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 50,
                    endRadius: 550
                )
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: currentPage)
            
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
        }
    }
    
    // MARK: - ページコンポーネント
    
    private func pageView(for page: PageContent) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // プレミアムな浮遊・光彩アイコンエリア
            ZStack {
                // 背後の光彩シャドウ
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)
                
                // グラデーションボーダー
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [page.color.opacity(0.6), page.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                
                // ガラスモフィズム背景
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 110, height: 110)
                    .shadow(color: page.color.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // メインアイコン
                Image(systemName: page.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 20)
            
            Text(page.title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if currentPage > 0 { currentPage -= 1 }
                }
            } label: {
                Text("戻る")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 80, height: 44, alignment: .leading)
            }
            .opacity(currentPage == 0 ? 0 : 1) // 1ページ目は非表示だがレイアウトは維持
            
            Spacer()
            
            // ページインジケーター（カプセル型インジケーター）
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? pages[currentPage].color : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 20 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            
            Spacer()
            
            // 次へ / はじめる ボタン
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentPage == pages.count - 1 ? "今すぐ始める" : "次へ")
                        .font(.system(size: 16, weight: .bold))
                    if currentPage == pages.count - 1 {
                        Image(systemName: "chevron.right.circle.fill")
                    }
                }
                .foregroundStyle(.white)
                .frame(width: currentPage == pages.count - 1 ? 160 : 100, height: 48, alignment: .center)
                .background(
                    LinearGradient(
                        colors: currentPage == pages.count - 1
                            ? [pages[currentPage].color, pages[currentPage].color.opacity(0.7)]
                            : [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: pages[currentPage].color.opacity(0.4), radius: 8, x: 0, y: 4)
                .scaleEffect(currentPage == pages.count - 1 ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
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
