//
//  ReductionCelebrationView.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/21.
//

import SwiftUI

/// 固定費削減に成功した際にお祝いするプレミアムなハーフシート。
struct ReductionCelebrationView: View {
    @Environment(\.dismiss) private var dismiss

    let serviceName: String
    let amount: Decimal
    let billingCycle: BillingCycle
    let category: Category
    let iconName: String

    @State private var animateItems = false
    @State private var animateSparkles = false

    var yearlySavings: Decimal {
        amount * billingCycle.yearlyMultiplier
    }

    var monthlySavings: Decimal {
        amount * billingCycle.monthlyMultiplier
    }

    // 浮いたお金で買えるものの例えを動的に算出
    var savingConcept: String {
        let yearlyDouble = NSDecimalNumber(decimal: yearlySavings).doubleValue
        if yearlyDouble < 3000 {
            let count = max(1, Int(yearlyDouble / 500))
            return "カフェラテ 約\(count)杯分 ☕️"
        } else if yearlyDouble < 10000 {
            let count = max(1, Int(yearlyDouble / 900))
            return "美味しいラーメン 約\(count)杯分 🍜"
        } else if yearlyDouble < 30000 {
            let count = max(1, Int(yearlyDouble / 2000))
            return "映画の鑑賞チケット 約\(count)枚分 🎬"
        } else if yearlyDouble < 80000 {
            let count = max(1, Int(yearlyDouble / 10000))
            return "ちょっと贅沢なコースディナー 約\(count)回分 🍽️"
        } else if yearlyDouble < 150000 {
            let count = max(1, Int(yearlyDouble / 50000))
            return "温泉国内旅行 約\(count)回分 ✈️"
        } else {
            return "最新のハイスペックタブレット 📱"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 12)

            // お祝いの王冠・アイコンエリア
            ZStack {
                // 背景のスパークルリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.4), Color.teal.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 110, height: 110)
                    .scaleEffect(animateSparkles ? 1.15 : 0.95)
                    .opacity(animateSparkles ? 0.0 : 1.0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animateSparkles)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.15), Color.teal.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: iconName)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateItems ? 1.0 : 0.3)
                    .rotationEffect(.degrees(animateItems ? 360 : 0))
                    .animation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0), value: animateItems)
                
                // クラッカー・バブル
                Text("🎉")
                    .font(.title)
                    .offset(x: -50, y: -40)
                    .scaleEffect(animateItems ? 1.0 : 0.0)
                    .opacity(animateItems ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2), value: animateItems)

                Text("✨")
                    .font(.title2)
                    .offset(x: 50, y: -30)
                    .scaleEffect(animateItems ? 1.0 : 0.0)
                    .opacity(animateItems ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.3), value: animateItems)
            }
            .padding(.vertical, 10)

            VStack(spacing: 8) {
                Text("削減成功！固定費を浮かせました")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1.5)

                Text(serviceName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            // 削減額サマリー
            VStack(spacing: 12) {
                Text("年間でこれだけ浮きます！")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(CurrencyHelper.formatted(amount: yearlySavings))
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateItems ? 1.0 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateItems)
                
                Text("（月額換算で \(CurrencyHelper.formatted(amount: monthlySavings))）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // ゲーミフィケーション: 浮いたお金の例え
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("浮いたお金のインパクトイメージ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

                Text(savingConcept)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.3), lineWidth: 1.5)
            )

            Spacer()

            VStack(spacing: 12) {
                // SNSシェアボタン
                Button {
                    shareToSNS()
                } label: {
                    Label("実績をSNSでシェア", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                }

                // 完了ボタン
                Button {
                    dismiss()
                } label: {
                    Text("やったね！")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(24)
        .onAppear {
            animateItems = true
            animateSparkles = true
            
            // Haptic Feedback (iOS用)
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            #endif
            
            // ASO対策: 削減お祝いアニメーションが表示された瞬間、2.0秒遅延でレビューを自動要求（Aha! Moment 2）
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ReviewRequestService.shared.requestReviewIfSavingsAchieved()
            }
        }
    }

    /// 削減成果カードを画像として生成し、SNSシェア用の共有シートを起動します。
    @MainActor
    private func shareToSNS() {
        #if os(iOS)
        let card = ShareSavingsCard(
            title: "固定費の削減に成功！\n「\(serviceName)」を解約しました",
            yearlySavings: yearlySavings,
            monthlySavings: monthlySavings,
            serviceCount: 1
        )
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0 // 高解像度画像にするためのスケール設定
        
        if let image = renderer.uiImage {
            shareImage(image)
        }
        #else
        shareImage("dummy")
        #endif
    }
}

#Preview {
    ReductionCelebrationView(
        serviceName: "Netflix Premium",
        amount: Decimal(1980),
        billingCycle: .monthly,
        category: .entertainment,
        iconName: "tv"
    )
}
