//
//  ReviewWizardView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

struct ReviewWizardView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// ダッシュボード等から渡されるすべてのアクティブなサブスクリプション
    let activeSubscriptions: [Subscription]
    
    @State private var viewModel = ReviewWizardViewModel()
    @State private var cardOffset: CGSize = .zero
    
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }
    
    enum SwipeDirection {
        case left, right, up
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                // 動的なネオン背景光彩 ＆ スワイプガイド（動作中のみ）
                if !viewModel.isFinished && !viewModel.subscriptions.isEmpty {
                    neonBackgroundGlow
                    swipePreGuides
                }
                
                if viewModel.isFinished {
                    ReviewSummaryView(viewModel: viewModel, dismissAction: { dismiss() })
                } else if viewModel.subscriptions.isEmpty {
                    ContentUnavailableView(
                        "見直し対象がありません",
                        systemImage: "checkmark.seal.fill",
                        description: Text("現在アクティブなサブスクリプションはありません。")
                    )
                } else {
                    wizardContent
                }
            }
            .navigationTitle(viewModel.isFinished ? "見直し結果" : "サブスク見直し")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.start(with: activeSubscriptions)
        }
    }
    
    // MARK: - ウィザードUI
    
    private var wizardContent: some View {
        VStack(spacing: 24) {
            // プログレス表示
            ProgressView(
                value: Double(viewModel.currentIndex),
                total: Double(viewModel.subscriptions.count)
            )
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Text("\(viewModel.currentIndex + 1) / \(viewModel.subscriptions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // カードスタック
            ZStack {
                let count = viewModel.subscriptions.count
                let index = viewModel.currentIndex
                
                if index + 1 < count {
                    // 次のカード（背景用）
                    let nextSub = viewModel.subscriptions[index + 1]
                    subscriptionCard(for: nextSub)
                        .scaleEffect(0.95)
                        .opacity(0.5)
                        .blur(radius: 0.5)
                        .offset(y: 12)
                }
                
                if index < count {
                    // 現在のカード（最前面）
                    let currentSub = viewModel.subscriptions[index]
                    subscriptionCard(for: currentSub)
                        .offset(cardOffset)
                        .rotationEffect(Angle(degrees: Double(cardOffset.width / 15)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    cardOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    let threshold: CGFloat = 130
                                    let x = gesture.translation.width
                                    let y = gesture.translation.height
                                    
                                    if x > threshold {
                                        swipeOut(to: .right) {
                                            viewModel.markCurrent(as: .keep)
                                        }
                                    } else if x < -threshold {
                                        swipeOut(to: .left) {
                                            viewModel.markCurrent(as: .cancelCandidate)
                                        }
                                    } else if y < -threshold {
                                        swipeOut(to: .up) {
                                            viewModel.markCurrent(as: .changePlan)
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                            cardOffset = .zero
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 440)
            
            Spacer()
            
            // アクションボタン
            actionButtons
                .padding(.bottom, 32)
        }
    }
    
    /// サブスクリプションを大きく表示するカード
    private func subscriptionCard(for sub: Subscription) -> some View {
        VStack(spacing: 24) {
            Image(systemName: sub.iconName)
                .font(.system(size: 56))
                .foregroundStyle(.white)
                .padding(24)
                .background(
                    Circle()
                        .fill(sub.category.color.opacity(0.2))
                        .shadow(color: sub.category.color.opacity(0.6), radius: 12)
                )
                .overlay(
                    Circle()
                        .stroke(sub.category.color.opacity(0.4), lineWidth: 2)
                )
                .padding(.top, 16)
            
            VStack(spacing: 8) {
                Text(sub.name)
                    .font(.title2)
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(sub.category.displayName, systemImage: sub.category.iconName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(sub.category.color.opacity(0.15))
                        .foregroundStyle(sub.category.color)
                        .clipShape(Capsule())
                    
                    if sub.isTrial {
                        Text("無料体験中")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(CurrencyHelper.formatted(amount: sub.amount))
                        .font(.system(size: 32, weight: .bold))
                    Text(" / \(sub.billingCycle.displayName)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(sub.satisfaction)")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(Capsule())
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.clockwise.heart.fill")
                            .foregroundColor(.pink)
                        Text(sub.usageFrequency.displayName.replacingOccurrences(of: "（.*）", with: "", options: .regularExpression, range: nil))
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 16)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: 420)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear, .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 24)
        .overlay(
            ZStack {
                // KEEP (右スワイプ)
                if cardOffset.width > 20 {
                    stampOverlay(text: "KEEP", color: currentTheme.color, angle: -15)
                        .opacity(min(1.0, Double((cardOffset.width - 20) / 80)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(32)
                }
                
                // CANCEL (左スワイプ)
                if cardOffset.width < -20 {
                    stampOverlay(text: "CANCEL", color: .red, angle: 15)
                        .opacity(min(1.0, Double((-cardOffset.width - 20) / 80)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(32)
                }
                
                // CHANGE PLAN (上スワイプ)
                if cardOffset.height < -20 {
                    stampOverlay(text: "CHANGE", color: .orange, angle: 0)
                        .opacity(min(1.0, Double((-cardOffset.height - 20) / 80)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(32)
                }
            }
        )
        .id(sub.id)
    }
    
    private func stampOverlay(text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 3)
                    .shadow(color: color.opacity(0.8), radius: 5)
            )
            .rotationEffect(Angle(degrees: angle))
            .shadow(color: color.opacity(0.5), radius: 3)
    }
    
    private func swipeOut(to direction: SwipeDirection, completion: @escaping () -> Void) {
        let targetOffset: CGSize
        switch direction {
        case .left:
            targetOffset = CGSize(width: -600, height: cardOffset.height)
        case .right:
            targetOffset = CGSize(width: 600, height: cardOffset.height)
        case .up:
            targetOffset = CGSize(width: cardOffset.width, height: -800)
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cardOffset = targetOffset
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
            cardOffset = .zero
        }
    }
    
    /// 見直しの仕分けアクションボタン
    private var actionButtons: some View {
        HStack(spacing: 32) {
            // 解約候補ボタン
            Button {
                swipeOut(to: .left) {
                    viewModel.markCurrent(as: .cancelCandidate)
                }
            } label: {
                actionButtonLabel(title: "解約候補", icon: "trash", color: .red)
            }
            
            // プラン変更ボタン
            Button {
                swipeOut(to: .up) {
                    viewModel.markCurrent(as: .changePlan)
                }
            } label: {
                actionButtonLabel(title: "変更検討", icon: "arrow.triangle.2.circlepath", color: .orange)
            }
            
            // キープボタン
            Button {
                swipeOut(to: .right) {
                    viewModel.markCurrent(as: .keep)
                }
            } label: {
                actionButtonLabel(title: "キープ", icon: "checkmark", color: currentTheme.color)
            }
        }
        .padding(.horizontal)
    }
    
    private func actionButtonLabel(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .foregroundStyle(color)
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }

    // MARK: - プレミアムネオン背景 ＆ 視覚ガイド

    /// スワイプのドラッグ移動量に応じたダイナミックなネオン光彩背景
    private var neonBackgroundGlow: some View {
        ZStack {
            // 右スワイプ (キープ) -> テーマカラー
            if cardOffset.width > 0 {
                RadialGradient(
                    colors: [currentTheme.color.opacity(Double(min(0.20, cardOffset.width / 400))), Color.clear],
                    center: .trailing,
                    startRadius: 20,
                    endRadius: 350
                )
                .ignoresSafeArea()
            }
            
            // 左スワイプ (解約候補) -> ネオンレッド 🔴
            if cardOffset.width < 0 {
                RadialGradient(
                    colors: [Color.red.opacity(Double(min(0.20, -cardOffset.width / 400))), Color.clear],
                    center: .leading,
                    startRadius: 20,
                    endRadius: 350
                )
                .ignoresSafeArea()
            }
            
            // 上スワイプ (プラン変更検討) -> ネオンオレンジ 🟡
            if cardOffset.height < 0 {
                RadialGradient(
                    colors: [Color.orange.opacity(Double(min(0.20, -cardOffset.height / 400))), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 350
                )
                .ignoresSafeArea()
            }
        }
    }

    /// 画面の端に浮かび上がるうっすらとしたスワイプ方向プレガイド
    private var swipePreGuides: some View {
        GeometryReader { geometry in
            ZStack {
                // 左ガイド：解約候補
                let leftOpacity = cardOffset.width < 0 
                    ? min(0.85, 0.15 + Double(-cardOffset.width / 120)) 
                    : max(0.0, 0.15 - Double(cardOffset.width / 40))
                
                HStack {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.8), radius: 6)
                        Text("解約候補")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 16)
                    .opacity(leftOpacity)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                
                // 右ガイド：キープ
                let rightOpacity = cardOffset.width > 0 
                    ? min(0.85, 0.15 + Double(cardOffset.width / 120)) 
                    : max(0.0, 0.15 - Double(-cardOffset.width / 40))
                
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(currentTheme.color)
                            .shadow(color: currentTheme.color.opacity(0.8), radius: 6)
                        Text("キープ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(currentTheme.color)
                    }
                    .padding(.trailing, 16)
                    .opacity(rightOpacity)
                }
                .frame(maxHeight: .infinity)
                
                // 上ガイド：プラン変更検討
                let topOpacity = cardOffset.height < 0 
                    ? min(0.85, 0.15 + Double(-cardOffset.height / 120)) 
                    : max(0.0, 0.15 - Double(abs(cardOffset.width) / 80))
                
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.8), radius: 6)
                        Text("プラン変更")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 110)
                    .opacity(topOpacity)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .allowsHitTesting(false) // ドラッグジェスチャー等のタッチイベントを完全に透過
    }
}
