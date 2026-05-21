//
//  ShareSavingsCard.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/21.
//

import SwiftUI

/// SNS（XやInstagram等）でシェアするための高品位な実績カード画像用のビュー。
/// 画面表示だけでなく、ImageRenderer によるUIImage化に最適化された 320x420 サイズのカード。
struct ShareSavingsCard: View {
    let title: String
    let yearlySavings: Decimal
    let monthlySavings: Decimal
    let serviceCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー: アプリロゴとカテゴリ表記
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text("コテサク")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text("固定費削減レポート")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            // 削減成功のアイコン演出
            ZStack {
                // 外側の輝き（ぼかしサークル）
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)

                // 中間の線丸
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.green.opacity(0.5), .teal.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 76, height: 76)

                // インナー背景
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)

                // メインチェックマーク
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.vertical, 8)

            // メインタイトル
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // 実績を表示するガラスモフィズムカード
            VStack(spacing: 8) {
                Text("年間の浮いた固定費")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.5)

                Text(CurrencyHelper.formatted(amount: yearlySavings))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("（月額換算 \(CurrencyHelper.formatted(amount: monthlySavings))）")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.vertical, 6)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Text("\(serviceCount)件 のサービスをスッキリ削減！")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .white.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
            )
            .padding(.horizontal, 24)

            Spacer()

            // フッター: アプリ紹介タグライン
            VStack(spacing: 4) {
                Text("賢くサブスク・固定費を管理して貯金を増やそう")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                Text("コテサクで家計をスマートに改善")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.bottom, 24)
        }
        .frame(width: 320, height: 420)
        // カード全体の背景: プレミアムなダークトーン＆グラデーション
        .background(
            ZStack {
                // ベースのダークカラー
                Color(red: 0.06, green: 0.08, blue: 0.14)
                
                // 光彩効果としてのグラデーション重ね合わせ
                RadialGradient(
                    colors: [Color.green.opacity(0.15), Color.clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 280
                )
                
                RadialGradient(
                    colors: [Color.teal.opacity(0.15), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: 280
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ShareSavingsCard(
        title: "固定費の削減に成功！",
        yearlySavings: Decimal(23760),
        monthlySavings: Decimal(1980),
        serviceCount: 1
    )
}
