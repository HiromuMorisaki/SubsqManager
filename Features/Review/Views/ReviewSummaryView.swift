//
//  ReviewSummaryView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// 見直し結果のサマリーを表示し、一括解約アクションを提供するView
struct ReviewSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    
    let viewModel: ReviewWizardViewModel
    let dismissAction: () -> Void
    
    @State private var showingConfirmation = false
    @State private var hasConfirmed = false
    
    // お祝い画面（セレブレーション）用ステート
    @State private var showingCelebration = false
    @State private var celebrationName = ""
    @State private var celebrationIcon = ""
    @State private var celebrationCategory: Category = .other
    @State private var celebrationAmount: Decimal = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // ヘッダー（お祝い/結果）
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                        .padding(.top, 20)
                    
                    Text("見直し完了！")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if viewModel.cancelCandidates.isEmpty {
                        Text("現在解約すべきサブスクはありません。\n無駄のない素晴らしい管理です！")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("解約候補をすべて解約すると…")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("年間")
                                .font(.subheadline)
                            
                            Text(CurrencyHelper.formatted(amount: viewModel.potentialYearlySavings))
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                            
                            Text("の節約になります！")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(.horizontal)
                
                // 解約候補リスト
                if !viewModel.cancelCandidates.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("解約候補リスト (\(viewModel.cancelCandidates.count)件)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.cancelCandidates) { sub in
                            HStack {
                                Image(systemName: sub.iconName)
                                    .foregroundStyle(.red)
                                    .frame(width: 30)
                                
                                Text(sub.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text(CurrencyHelper.formatted(amount: sub.monthlyAmount))
                                        .fontWeight(.medium)
                                    Text("/月")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                    
                    // 一括解約ボタン
                    Button(role: .destructive) {
                        showingConfirmation = true
                    } label: {
                        Text("解約候補を一括で解約済みにする")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasConfirmed ? Color.gray : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .disabled(hasConfirmed)
                }
                
                // 完了ボタン
                Button {
                    dismissAction()
                } label: {
                    Text(hasConfirmed || viewModel.cancelCandidates.isEmpty ? "ダッシュボードへ戻る" : "スキップして戻る")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingCelebration) {
            ReductionCelebrationView(
                serviceName: celebrationName,
                amount: celebrationAmount,
                billingCycle: .monthly,
                category: celebrationCategory,
                iconName: celebrationIcon
            )
        }
        .alert("一括解約の確認", isPresented: $showingConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削減実績に記録する", role: .destructive) {
                // 削除を実行する前に金額と件数を退避
                let totalMonthly = viewModel.potentialMonthlySavings
                let count = viewModel.cancelCandidates.count
                let firstSubName = viewModel.cancelCandidates.first?.name ?? ""
                let firstSubIcon = viewModel.cancelCandidates.first?.iconName ?? "sparkles"
                let firstSubCategory = viewModel.cancelCandidates.first?.category ?? .other
                
                withAnimation {
                    viewModel.confirmCancellations(using: modelContext)
                    hasConfirmed = true
                    
                    // 保存した値を用いてお祝い画面用のデータをセット
                    self.celebrationName = count == 1
                        ? firstSubName
                        : "解約候補のサブスク（\(count)件）"
                    self.celebrationIcon = count == 1
                        ? firstSubIcon
                        : "sparkles.rectangle.stack"
                    self.celebrationCategory = count == 1
                        ? firstSubCategory
                        : .other
                    self.celebrationAmount = totalMonthly
                    
                    showingCelebration = true
                }
            }
        } message: {
            Text("対象サブスクリプションを削減実績に記録し、アクティブ契約から削除します。\n\n※実際のサービスの解約は、各公式サイトから手動で行う必要があります。")
        }
    }
}
