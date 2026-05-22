//
//  SubscriptionFormSections.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI

/// サブスク登録・編集フォームの共通セクション。
/// AddSubscriptionView と EditSubscriptionView の両方から再利用する。
///
/// ### @Binding について
/// 親View（AddまたはEdit）のViewModel のプロパティへの双方向バインディング。
/// ユーザーの入力がリアルタイムに親の ViewModel に反映される。
struct SubscriptionFormSections: View {

    @Binding var name: String
    @Binding var amountText: String
    @Binding var billingCycle: BillingCycle
    @Binding var category: Category
    @Binding var startDate: Date
    @Binding var hasTrial: Bool
    @Binding var trialEndDate: Date
    @Binding var hasEndDate: Bool
    @Binding var endDate: Date
    @Binding var iconName: String
    @Binding var notes: String
    @Binding var satisfaction: Int
    @Binding var usageFrequency: UsageFrequency

    var body: some View {
        Group {
            basicInfoSection
            billingSection
            costPerformanceSection
            endDateSection
            trialSection
            categorySection
            iconSection
            notesSection
        }
    }

    // MARK: - セクション

    /// サブスク名と金額の入力セクション
    private var basicInfoSection: some View {
        Section(header: Text("基本情報").id("formInputFields")) {
            TextField("サブスク名", text: $name)
            TextField("金額", text: $amountText)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
        }
    }

    /// 請求サイクルと開始日の設定セクション
    private var billingSection: some View {
        Section("請求設定") {
            Picker("請求サイクル", selection: $billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.displayName).tag(cycle)
                }
            }
            DatePicker("開始日", selection: $startDate, displayedComponents: .date)
        }
    }

    /// 無料トライアルの設定セクション
    private var trialSection: some View {
        Section("無料トライアル") {
            Toggle("無料トライアル中", isOn: $hasTrial)
            
            if hasTrial {
                DatePicker("トライアル終了日", selection: $trialEndDate, displayedComponents: .date)
            }
        }
    }

    /// 終了予定日の設定セクション
    private var endDateSection: some View {
        Section("終了予定") {
            Toggle("終了日を設定する", isOn: $hasEndDate)
            
            if hasEndDate {
                DatePicker("サブスク終了日", selection: $endDate, displayedComponents: .date)
            }
        }
    }

    /// カテゴリ選択セクション
    private var categorySection: some View {
        Section("カテゴリ") {
            Picker("カテゴリ", selection: $category) {
                ForEach(Category.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                }
            }
        }
    }

    /// アイコン選択セクション（SF Symbolから選択）
    private var iconSection: some View {
        Section("アイコン") {
            Picker("アイコン", selection: $iconName) {
                ForEach(Self.availableIcons, id: \.self) { icon in
                    Label(icon, systemImage: icon).tag(icon)
                }
            }
        }
    }

    /// メモ入力セクション
    private var notesSection: some View {
        Section("メモ") {
            TextField("メモ（任意）", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    /// コスパ診断のための満足度と利用頻度の設定セクション
    private var costPerformanceSection: some View {
        Section("満足度と利用頻度（コスパ診断）") {
            HStack {
                Text("満足度")
                Spacer()
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= satisfaction ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(star <= satisfaction ? Color.yellow : Color(.systemGray4))
                        .onTapGesture {
                            satisfaction = star
                        }
                }
            }
            .padding(.vertical, 4)
            
            Picker("利用頻度", selection: $usageFrequency) {
                ForEach(UsageFrequency.allCases) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }
        }
    }

    // MARK: - 定数

    /// アイコン選択肢として表示するSF Symbol名のリスト
    /// デフォルトのリストに加えて、プリセットで使われているすべてのアイコンを網羅する
    private static let availableIcons: [String] = {
        let defaultIcons = [
            "creditcard", "tv", "music.note", "film",
            "gamecontroller", "book", "newspaper",
            "cloud", "wifi", "desktopcomputer",
            "briefcase", "heart", "star"
        ]
        let presetIcons = SubscriptionPreset.defaultPresets.map { $0.iconName }
        
        var allIcons = defaultIcons + presetIcons
        var seen = Set<String>()
        // 重複を削除しつつ順序を保持
        return allIcons.filter { seen.insert($0).inserted }
    }()
}
