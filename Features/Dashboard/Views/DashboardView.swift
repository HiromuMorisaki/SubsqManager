//
//  DashboardView.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import SwiftData

/// ダッシュボード画面。
/// 月額合計・年額合計のサマリーカードと、直近の請求予定リストを表示する。
struct DashboardView: View {

    @Query(
        filter: #Predicate<Subscription> { $0.isActive == true },
        sort: \Subscription.nextPaymentDate
    ) private var subscriptions: [Subscription]

    @State private var viewModel = DashboardViewModel()
    @State private var showingReviewWizard = false
    @State private var showingAddSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if subscriptions.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 20) {
                        reviewButton
                        summaryCards
                        CategoryChartView(data: viewModel.monthlyAmountByCategory(subscriptions))
                        upcomingSection
                    }
                    .padding()
                }
            }
            .navigationTitle("ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingReviewWizard) {
                ReviewWizardView(activeSubscriptions: subscriptions)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
            }
        }
    }
    
    // MARK: - 空状態（Empty State）
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            Image(systemName: "tray.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("サブスクがありません")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("まずは最初のサブスクリプションを登録して、\nダッシュボードを作成しましょう。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddSheet = true
            } label: {
                Text("最初のサブスクを登録する")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 見直しボタン

    private var reviewButton: some View {
        Button {
            showingReviewWizard = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("サブスクを見直す")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - サマリーカード

    /// 月額・年額合計を表示するカードエリア
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCardView(
                title: "月額合計",
                amount: viewModel.totalMonthlyAmount(subscriptions),
                iconName: "calendar",
                color: .blue
            )
            SummaryCardView(
                title: "年額合計",
                amount: viewModel.totalYearlyAmount(subscriptions),
                iconName: "calendar.badge.clock",
                color: .purple
            )
        }
    }

    // MARK: - 直近の請求予定

    /// 直近の請求予定セクション
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近の請求予定")
                .font(.headline)

            let upcoming = viewModel.upcomingSubscriptions(subscriptions)

            if upcoming.isEmpty {
                Text("予定されている請求はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(upcoming) { subscription in
                    UpcomingRowView(subscription: subscription)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
