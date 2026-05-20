//
//  SubscriptionPreset.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import Foundation

/// サブスクの料金プラン
struct SubscriptionPlan: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Decimal
    let billingCycle: BillingCycle
}

/// サブスク登録時のプリセット入力用データ構造
struct SubscriptionPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: Category
    let iconName: String
    let plans: [SubscriptionPlan]
    
    // 代表的なサブスクのプリセットリスト
    static let defaultPresets: [SubscriptionPreset] = [
        // MARK: - エンタメ (Entertainment)
        SubscriptionPreset(
            name: "Netflix",
            category: .entertainment,
            iconName: "film",
            plans: [
                SubscriptionPlan(name: "広告つきスタンダード", amount: 790, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード", amount: 1490, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム", amount: 1980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Spotify",
            category: .entertainment,
            iconName: "music.note",
            plans: [
                SubscriptionPlan(name: "Student", amount: 480, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "Duo", amount: 1280, billingCycle: .monthly),
                SubscriptionPlan(name: "Family", amount: 1580, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "YouTube Premium",
            category: .entertainment,
            iconName: "play.rectangle",
            plans: [
                SubscriptionPlan(name: "学割プラン", amount: 780, billingCycle: .monthly),
                SubscriptionPlan(name: "個人プラン", amount: 1280, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリープラン", amount: 2280, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Apple Music",
            category: .entertainment,
            iconName: "applelogo",
            plans: [
                SubscriptionPlan(name: "学生プラン", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "個人プラン", amount: 1080, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリープラン", amount: 1680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Amazon Music Unlimited",
            category: .entertainment,
            iconName: "music.mic",
            plans: [
                SubscriptionPlan(name: "プライム会員(月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "プライム会員(年額)", amount: 9800, billingCycle: .yearly),
                SubscriptionPlan(name: "一般会員(月額)", amount: 1080, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Disney+",
            category: .entertainment,
            iconName: "sparkles.tv",
            plans: [
                SubscriptionPlan(name: "スタンダード(月額)", amount: 990, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード(年額)", amount: 9900, billingCycle: .yearly),
                SubscriptionPlan(name: "プレミアム(月額)", amount: 1320, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(年額)", amount: 13200, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Hulu",
            category: .entertainment,
            iconName: "play.circle",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1026, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "U-NEXT",
            category: .entertainment,
            iconName: "play.tv",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 2189, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "DAZN",
            category: .entertainment,
            iconName: "sportscourt",
            plans: [
                SubscriptionPlan(name: "Standard(月額)", amount: 4200, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard(年間/月々払い)", amount: 3200, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard(年間/一括)", amount: 32000, billingCycle: .yearly)
            ]
        ),
        
        // MARK: - ライフスタイル (Lifestyle)
        SubscriptionPreset(
            name: "Amazon Prime",
            category: .lifestyle,
            iconName: "cart",
            plans: [
                SubscriptionPlan(name: "月間プラン", amount: 600, billingCycle: .monthly),
                SubscriptionPlan(name: "年間プラン", amount: 5900, billingCycle: .yearly),
                SubscriptionPlan(name: "Prime Student(月間)", amount: 300, billingCycle: .monthly),
                SubscriptionPlan(name: "Prime Student(年間)", amount: 2950, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Cookpad",
            category: .lifestyle,
            iconName: "fork.knife",
            plans: [
                SubscriptionPlan(name: "プレミアムサービス", amount: 400, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Kindle Unlimited",
            category: .lifestyle,
            iconName: "book",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 980, billingCycle: .monthly)
            ]
        ),
        // MARK: - ゲーム (Game)
        SubscriptionPreset(
            name: "Nintendo Switch Online",
            category: .game,
            iconName: "gamecontroller",
            plans: [
                SubscriptionPlan(name: "個人(1ヶ月)", amount: 306, billingCycle: .monthly),
                SubscriptionPlan(name: "個人(12ヶ月)", amount: 2400, billingCycle: .yearly),
                SubscriptionPlan(name: "ファミリー(12ヶ月)", amount: 4500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "PlayStation Plus",
            category: .game,
            iconName: "logo.playstation",
            plans: [
                SubscriptionPlan(name: "エッセンシャル(月額)", amount: 850, billingCycle: .monthly),
                SubscriptionPlan(name: "エクストラ(月額)", amount: 1300, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(月額)", amount: 1550, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Xbox Game Pass",
            category: .game,
            iconName: "logo.xbox",
            plans: [
                SubscriptionPlan(name: "Core(月額)", amount: 842, billingCycle: .monthly),
                SubscriptionPlan(name: "Ultimate(月額)", amount: 1210, billingCycle: .monthly)
            ]
        ),
        
        // MARK: - ヘルスケア・フィットネス (Healthcare)
        SubscriptionPreset(
            name: "エニタイムフィットネス",
            category: .healthcare,
            iconName: "figure.run",
            plans: [
                SubscriptionPlan(name: "月額プラン(店舗により異なる)", amount: 7480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "JOYFIT24",
            category: .healthcare,
            iconName: "figure.run",
            plans: [
                SubscriptionPlan(name: "ナショナル会員(月額)", amount: 7678, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "FIT PLACE24",
            category: .healthcare,
            iconName: "dumbbell",
            plans: [
                SubscriptionPlan(name: "プレミアム会員(月額)", amount: 3278, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "カーブス (Curves)",
            category: .healthcare,
            iconName: "figure.mind.and.body",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 6820, billingCycle: .monthly),
                SubscriptionPlan(name: "年割プラン(月々)", amount: 5720, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ゴールドジム",
            category: .healthcare,
            iconName: "figure.strengthtraining.traditional",
            plans: [
                SubscriptionPlan(name: "レギュラー(月額)", amount: 11000, billingCycle: .monthly),
                SubscriptionPlan(name: "マスター(月額)", amount: 14300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "chocoZAP (チョコザップ)",
            category: .healthcare,
            iconName: "figure.run",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 3278, billingCycle: .monthly)
            ]
        ),
        
        // MARK: - ファイナンス (Financial)
        SubscriptionPreset(
            name: "マネーフォワード ME",
            category: .financial,
            iconName: "yensign.circle",
            plans: [
                SubscriptionPlan(name: "プレミアムサービス(月額)", amount: 500, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアムサービス(年額)", amount: 5300, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Zaim",
            category: .financial,
            iconName: "yensign.square",
            plans: [
                SubscriptionPlan(name: "プレミアム(月額)", amount: 480, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(年額)", amount: 4800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "freee",
            category: .financial,
            iconName: "doc.text",
            plans: [
                SubscriptionPlan(name: "スターター(月額)", amount: 1180, billingCycle: .monthly),
                SubscriptionPlan(name: "スターター(年額)", amount: 11760, billingCycle: .yearly)
            ]
        ),
        
        // MARK: - 仕事・学習 (Work)
        SubscriptionPreset(
            name: "Adobe Creative Cloud",
            category: .work,
            iconName: "paintbrush.pointed",
            plans: [
                SubscriptionPlan(name: "コンプリートプラン", amount: 6480, billingCycle: .monthly),
                SubscriptionPlan(name: "学生・教職員向け", amount: 2180, billingCycle: .monthly),
                SubscriptionPlan(name: "フォトプラン", amount: 1080, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Microsoft 365",
            category: .work,
            iconName: "doc.text",
            plans: [
                SubscriptionPlan(name: "Personal(月額)", amount: 1490, billingCycle: .monthly),
                SubscriptionPlan(name: "Personal(年額)", amount: 14900, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Notion",
            category: .work,
            iconName: "note.text",
            plans: [
                SubscriptionPlan(name: "Plus(月額)", amount: 1500, billingCycle: .monthly), // おおよそ
                SubscriptionPlan(name: "Plus(年額)", amount: 15000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Slack",
            category: .work,
            iconName: "bubble.left.and.bubble.right",
            plans: [
                SubscriptionPlan(name: "Pro(月額)", amount: 1050, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro(年額)", amount: 12600, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Zoom",
            category: .work,
            iconName: "video",
            plans: [
                SubscriptionPlan(name: "Pro(月額)", amount: 2125, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro(年額)", amount: 20100, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Canva",
            category: .work,
            iconName: "paintpalette",
            plans: [
                SubscriptionPlan(name: "Pro(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro(年額)", amount: 12000, billingCycle: .yearly)
            ]
        ),
        
        // MARK: - 教育 (Education)
        SubscriptionPreset(
            name: "Duolingo",
            category: .education,
            iconName: "character.book.closed",
            plans: [
                SubscriptionPlan(name: "Super(月額)", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "Super(年額)", amount: 9900, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "NewsPicks",
            category: .education,
            iconName: "newspaper",
            plans: [
                SubscriptionPlan(name: "プレミアム(月額)", amount: 1700, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(年額)", amount: 17000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "日経電子版",
            category: .education,
            iconName: "doc.plaintext",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 4277, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Coursera",
            category: .education,
            iconName: "graduationcap",
            plans: [
                SubscriptionPlan(name: "Plus(月額)", amount: 8800, billingCycle: .monthly) // レートによる
            ]
        ),
        
        // MARK: - 生成AI (Generative AI)
        SubscriptionPreset(
            name: "ChatGPT Plus",
            category: .ai,
            iconName: "brain.head.profile",
            plans: [
                SubscriptionPlan(name: "Plus ($20/月)", amount: 3100, billingCycle: .monthly) // 為替による目安
            ]
        ),
        SubscriptionPreset(
            name: "Gemini Advanced",
            category: .ai,
            iconName: "sparkles",
            plans: [
                SubscriptionPlan(name: "Google One AI Premium", amount: 2900, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Claude Pro",
            category: .ai,
            iconName: "cpu",
            plans: [
                SubscriptionPlan(name: "Pro ($20/月)", amount: 3100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Perplexity Pro",
            category: .ai,
            iconName: "magnifyingglass.circle",
            plans: [
                SubscriptionPlan(name: "Pro(月額 $20)", amount: 3100, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro(年額 $200)", amount: 31000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "GitHub Copilot",
            category: .ai,
            iconName: "terminal",
            plans: [
                SubscriptionPlan(name: "Individual(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Individual(年額)", amount: 15000, billingCycle: .yearly)
            ]
        ),
        
        // MARK: - インフラ・その他 (Other)
        SubscriptionPreset(
            name: "iCloud+",
            category: .other,
            iconName: "cloud",
            plans: [
                SubscriptionPlan(name: "50GB", amount: 130, billingCycle: .monthly),
                SubscriptionPlan(name: "200GB", amount: 400, billingCycle: .monthly),
                SubscriptionPlan(name: "2TB", amount: 1300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Google One",
            category: .other,
            iconName: "externaldrive",
            plans: [
                SubscriptionPlan(name: "ベーシック(100GB)", amount: 250, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード(200GB)", amount: 380, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(2TB)", amount: 1300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Dropbox",
            category: .other,
            iconName: "shippingbox",
            plans: [
                SubscriptionPlan(name: "Plus(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Plus(年額)", amount: 14400, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "1Password",
            category: .other,
            iconName: "key",
            plans: [
                SubscriptionPlan(name: "個人(月額)", amount: 450, billingCycle: .monthly), // 約$2.99
                SubscriptionPlan(name: "ファミリー(月額)", amount: 750, billingCycle: .monthly) // 約$4.99
            ]
        )
    ]
    
    /// カテゴリごとにプリセットをグループ化した辞書を返す
    static var groupedByCategory: [Category: [SubscriptionPreset]] {
        Dictionary(grouping: defaultPresets, by: { $0.category })
    }
}
