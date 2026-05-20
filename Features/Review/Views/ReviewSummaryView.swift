//
//  ReviewSummaryView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// 見直し結果のサマリーを表示し、一括解約アクションを提供するView
struct ReviewSummaryView: View {
    let viewModel: ReviewWizardViewModel
    let dismissAction: () -> Void
    
    @State private var showingConfirmation = false
    @State private var hasConfirmed = false
    
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
                                
                                Text(CurrencyHelper.formatted(amount: sub.monthlyAmount))
                                    .fontWeight(.medium)
                                    + Text("/月").font(.caption).foregroundStyle(.secondary)
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
        .alert("一括解約の確認", isPresented: $showingConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("解約済みにする", role: .destructive) {
                withAnimation {
                    viewModel.confirmCancellations()
                    hasConfirmed = true
                }
            }
        } message: {
            Text("アプリ上のステータスを「解約済み」に変更し、今後の合計金額から除外します。\n\n※実際のサービスの解約は、各公式サイトから手動で行う必要があります。")
        }
    }
}
