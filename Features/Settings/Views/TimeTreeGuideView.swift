//
//  TimeTreeGuideView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/23.
//

import SwiftUI

struct TimeTreeGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.neonGreen.rawValue
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRawValue) ?? .neonGreen }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [currentTheme.color.opacity(0.06), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダーカード
                        headerSection
                        
                        // API終了のお知らせ（親切な背景情報）
                        apiNoticeSection
                        
                        // ステップガイド
                        VStack(alignment: .leading, spacing: 18) {
                            Text("連携設定の手順 (簡単3ステップ)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 4)
                            
                            stepCard(
                                stepNumber: "1",
                                title: "コテサクで「カレンダー自動連携」を有効化",
                                description: "コテサクの「設定 ＞ カレンダー自動連携」をONにし、同期するカレンダー（例: 「コテサク予定」など）を選択します。"
                            )
                            
                            stepCard(
                                stepNumber: "2",
                                title: "iOS標準カレンダーに自動登録",
                                description: "コテサクに登録されたサブスクの「次回請求日」や「無料トライアル終了日」が、お使いのiPhoneの標準カレンダーへ自動登録されます。"
                            )
                            
                            stepCard(
                                stepNumber: "3",
                                title: "TimeTreeでiOSカレンダーを同期",
                                description: "TimeTreeアプリを開き、「設定 ＞ OSカレンダーの予定を表示」またはカレンダー設定内の「OSカレンダーの読み込み」から、コテサクが書き込んでいるiOSカレンダーを選択して読み込みます。"
                            )
                        }
                        
                        // アクションボタン
                        actionButtonsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("TimeTree 連携ガイド")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - サブビュー
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title)
                    .foregroundStyle(.green)
            }
            
            Text("TimeTree 自動同期ガイド")
                .font(.title3)
                .fontWeight(.black)
            
            Text("iOS標準カレンダーを介して、コテサクの請求スケジュールをTimeTreeへ安全に自動同期させることができます。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    private var apiNoticeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
                
                Text("外部API連携の終了にともなう仕様変更")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Text("TimeTree公式による「Connect App（外部連携API機能）」の2023年12月終了にともない、アクセストークンを用いた直接同期機能は終了しました。現在は、上記の「iOSカレンダーを介した間接同期」が唯一かつ推奨の連携方法となります。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func stepCard(stepNumber: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // ステップ番号の円形バッジ
            Text(stepNumber)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: currentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: currentTheme.color.opacity(0.3), radius: 3, y: 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button {
                openTimeTree()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.forward.app.fill")
                    Text("TimeTreeアプリを起動する")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: currentTheme.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: currentTheme.color.opacity(0.3), radius: 6, y: 3)
            }
            
            Text("※TimeTreeアプリがインストールされていない場合は自動的にApp Storeが開きます。")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }
    
    // MARK: - アクション
    
    private func openTimeTree() {
        let appScheme = "timetree://"
        let appStoreURL = "https://apps.apple.com/jp/app/id1084666324"
        let webURL = "https://timetreeapp.com/"
        
        guard let appURL = URL(string: appScheme) else { return }
        
        // まずTimeTreeアプリの直接起動を試みる（Info.plistのcanOpenURL判定を不要にする）
        UIApplication.shared.open(appURL, options: [:]) { success in
            if !success {
                // 起動に失敗した場合（アプリが入っていないなど）のフォールバック
                #if targetEnvironment(simulator)
                // シミュレータならブラウザで公式Webサイトを表示（「アドレスが無効です」エラーを完全回避）
                if let url = URL(string: webURL) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                #else
                // 実機ならApp Storeアプリを起動
                if let storeURL = URL(string: appStoreURL) {
                    UIApplication.shared.open(storeURL, options: [:], completionHandler: nil)
                }
                #endif
            }
        }
    }
}

#Preview {
    TimeTreeGuideView()
}
