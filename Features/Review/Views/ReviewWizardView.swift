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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.1).ignoresSafeArea()
                
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
            
            Text("\(viewModel.currentIndex + 1) / \(viewModel.subscriptions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // 現在のサブスク情報カード
            if viewModel.currentIndex < viewModel.subscriptions.count {
                let currentSub = viewModel.subscriptions[viewModel.currentIndex]
                subscriptionCard(for: currentSub)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            
            Spacer()
            
            // アクションボタン
            actionButtons
                .padding(.bottom, 32)
        }
    }
    
    /// サブスクリプションを大きく表示するカード
    private func subscriptionCard(for sub: Subscription) -> some View {
        VStack(spacing: 16) {
            Image(systemName: sub.iconName)
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .padding()
                .background(.regularMaterial)
                .clipShape(Circle())
            
            Text(sub.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Label(sub.category.displayName, systemImage: sub.category.iconName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if sub.isTrial {
                    Text("無料体験中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }
            
            Text(CurrencyHelper.formatted(amount: sub.amount))
                .font(.title2)
                .fontWeight(.semibold)
                + Text(" / \(sub.billingCycle.displayName)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal, 24)
        // カード切り替えアニメーションのためのID
        .id(sub.id)
    }
    
    /// 見直しの仕分けアクションボタン
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // 解約候補ボタン
            Button {
                withAnimation { viewModel.markCurrent(as: .cancelCandidate) }
            } label: {
                actionButtonLabel(title: "解約候補", icon: "trash", color: .red)
            }
            
            // プラン変更ボタン
            Button {
                withAnimation { viewModel.markCurrent(as: .changePlan) }
            } label: {
                actionButtonLabel(title: "変更検討", icon: "arrow.triangle.2.circlepath", color: .orange)
            }
            
            // キープボタン
            Button {
                withAnimation { viewModel.markCurrent(as: .keep) }
            } label: {
                actionButtonLabel(title: "キープ", icon: "checkmark", color: .green)
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
}
