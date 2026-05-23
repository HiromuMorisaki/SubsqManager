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
    
    // 代表的なサブスクのプリセットリスト (200種類以上)
    static let defaultPresets: [SubscriptionPreset] = [
        // MARK: - 音楽 (Music) - 10件
        SubscriptionPreset(
            name: "Spotify",
            category: .music,
            iconName: "music.note",
            plans: [
                SubscriptionPlan(name: "Student (学割)", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard (個人)", amount: 1080, billingCycle: .monthly),
                SubscriptionPlan(name: "Duo (カップル)", amount: 1480, billingCycle: .monthly),
                SubscriptionPlan(name: "Family (ファミリー)", amount: 1680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Apple Music",
            category: .music,
            iconName: "applelogo",
            plans: [
                SubscriptionPlan(name: "学生プラン", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "個人プラン", amount: 1080, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリープラン", amount: 1680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Amazon Music Unlimited",
            category: .music,
            iconName: "music.mic",
            plans: [
                SubscriptionPlan(name: "プライム会員(月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "プライム会員(年額)", amount: 9800, billingCycle: .yearly),
                SubscriptionPlan(name: "一般会員(月額)", amount: 1080, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "YouTube Music Premium",
            category: .music,
            iconName: "play.rectangle.fill",
            plans: [
                SubscriptionPlan(name: "学生プラン", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "個人プラン", amount: 1080, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリープラン", amount: 1680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "LINE MUSIC",
            category: .music,
            iconName: "music.quaver.bowl.and.waveform",
            plans: [
                SubscriptionPlan(name: "学生プラン", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "一般プラン", amount: 1080, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリープラン", amount: 1680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "AWA",
            category: .music,
            iconName: "waveform",
            plans: [
                SubscriptionPlan(name: "STANDARD(月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "STANDARD(年額)", amount: 9800, billingCycle: .yearly),
                SubscriptionPlan(name: "学生プラン", amount: 480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "dヒッツ",
            category: .music,
            iconName: "earphones",
            plans: [
                SubscriptionPlan(name: "500枠コース", amount: 550, billingCycle: .monthly),
                SubscriptionPlan(name: "Myヒッツなしコース", amount: 330, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "KKBOX",
            category: .music,
            iconName: "music.note.house",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Tower Records Music",
            category: .music,
            iconName: "music.quaver",
            plans: [
                SubscriptionPlan(name: "スタンダードプラン", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Rakuten Music",
            category: .music,
            iconName: "music.note.list",
            plans: [
                SubscriptionPlan(name: "スタンダードプラン", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "楽天カード/モバイル会員", amount: 780, billingCycle: .monthly),
                SubscriptionPlan(name: "ライトプラン", amount: 500, billingCycle: .monthly)
            ]
        ),

        // MARK: - 動画・エンタメ (Entertainment) - 20件
        SubscriptionPreset(
            name: "YouTube Premium",
            category: .entertainment,
            iconName: "play.rectangle.fill",
            plans: [
                SubscriptionPlan(name: "個人プラン(月額)", amount: 1480, billingCycle: .monthly),
                SubscriptionPlan(name: "個人プラン(年額)", amount: 14800, billingCycle: .yearly),
                SubscriptionPlan(name: "ファミリープラン", amount: 2980, billingCycle: .monthly),
                SubscriptionPlan(name: "学割プラン", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "X (Twitter)",
            category: .entertainment,
            iconName: "message",
            plans: [
                SubscriptionPlan(name: "Basic (月額)", amount: 368, billingCycle: .monthly),
                SubscriptionPlan(name: "Basic (年額)", amount: 3916, billingCycle: .yearly),
                SubscriptionPlan(name: "Premium (月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "Premium (年額)", amount: 10280, billingCycle: .yearly),
                SubscriptionPlan(name: "Premium+ (月額)", amount: 1960, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Netflix",
            category: .entertainment,
            iconName: "film",
            plans: [
                SubscriptionPlan(name: "広告つきスタンダード", amount: 890, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード", amount: 1590, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム", amount: 2290, billingCycle: .monthly)
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
                SubscriptionPlan(name: "月額プラン(1200pt付き)", amount: 2189, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ABEMA プレミアム",
            category: .entertainment,
            iconName: "tv.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 960, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Lemino プレミアム",
            category: .entertainment,
            iconName: "play.rectangle.on.rectangle",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 990, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Apple TV+",
            category: .entertainment,
            iconName: "appletv",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 900, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "DMM TV (DMMプレミアム)",
            category: .entertainment,
            iconName: "play.rectangle",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 550, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "niconico プレミアム",
            category: .entertainment,
            iconName: "tv",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 790, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 7900, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "WOWOW オンデマンド",
            category: .entertainment,
            iconName: "tv.circle",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 2530, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "dアニメストア",
            category: .entertainment,
            iconName: "play.circle.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 550, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "FODプレミアム",
            category: .entertainment,
            iconName: "play.tv.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 976, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "TELASA",
            category: .entertainment,
            iconName: "rectangle.inset.filled.and.person.filled",
            plans: [
                SubscriptionPlan(name: "見放題プラン", amount: 618, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "バンダイチャンネル",
            category: .entertainment,
            iconName: "play",
            plans: [
                SubscriptionPlan(name: "見放題会員", amount: 1100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ツイキャス メンバーシップ",
            category: .entertainment,
            iconName: "person.2.wave.2",
            plans: [
                SubscriptionPlan(name: "月額支援(500円)", amount: 500, billingCycle: .monthly),
                SubscriptionPlan(name: "月額支援(1000円)", amount: 1000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "SPOOX (スプークス)",
            category: .entertainment,
            iconName: "play.house",
            plans: [
                SubscriptionPlan(name: "バリュープラン", amount: 990, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Mnet Smart+",
            category: .entertainment,
            iconName: "sparkles.tv.fill",
            plans: [
                SubscriptionPlan(name: "ライトプラン", amount: 990, billingCycle: .monthly),
                SubscriptionPlan(name: "ベーシックプラン", amount: 1320, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアムプラン", amount: 2530, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Prime Videoチャンネル",
            category: .entertainment,
            iconName: "arrow.down.right.and.arrow.up.left.rect",
            plans: [
                SubscriptionPlan(name: "月額アニメ枠目安", amount: 550, billingCycle: .monthly),
                SubscriptionPlan(name: "月額映画枠目安", amount: 990, billingCycle: .monthly)
            ]
        ),

        // MARK: - マンガ・電子書籍 (Manga) - 15件
        SubscriptionPreset(
            name: "コミックシーモア",
            category: .manga,
            iconName: "book.closed.fill",
            plans: [
                SubscriptionPlan(name: "読み放題ライト", amount: 780, billingCycle: .monthly),
                SubscriptionPlan(name: "読み放題フル", amount: 1480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "BOOK☆WALKER",
            category: .manga,
            iconName: "book",
            plans: [
                SubscriptionPlan(name: "マンガ・雑誌 読み放題", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "文庫・ラノベ 読み放題", amount: 1100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "少年ジャンプ+",
            category: .manga,
            iconName: "character.book.closed.fill",
            plans: [
                SubscriptionPlan(name: "定期購読(週刊少年ジャンプ)", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "コミックDAYS",
            category: .manga,
            iconName: "books.vertical",
            plans: [
                SubscriptionPlan(name: "プレミアム(6誌購読)", amount: 720, billingCycle: .monthly),
                SubscriptionPlan(name: "もっとプレミアム(17誌)", amount: 960, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "マガポケ",
            category: .manga,
            iconName: "book.pages",
            plans: [
                SubscriptionPlan(name: "週刊少年マガジン定期購読", amount: 840, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "サンデーうぇぶり",
            category: .manga,
            iconName: "doc.text.image",
            plans: [
                SubscriptionPlan(name: "週刊少年サンデー定期購読", amount: 720, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "まんが王国",
            category: .manga,
            iconName: "crown",
            plans: [
                SubscriptionPlan(name: "月額コース1000", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "月額コース2000", amount: 2200, billingCycle: .monthly),
                SubscriptionPlan(name: "月額コース3000", amount: 3300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ebookjapan",
            category: .manga,
            iconName: "bookmark",
            plans: [
                SubscriptionPlan(name: "月額ポイントコース1000", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "月額ポイントコース2000", amount: 2200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "BookLive!",
            category: .manga,
            iconName: "bookmark.fill",
            plans: [
                SubscriptionPlan(name: "月額ポイントコース1000", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "月額ポイントコース2000", amount: 2200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "LINEマンガ",
            category: .manga,
            iconName: "message.and.waveform",
            plans: [
                SubscriptionPlan(name: "月額定額コース", amount: 1000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ピッコマ",
            category: .manga,
            iconName: "grid",
            plans: [
                SubscriptionPlan(name: "月額定額コース", amount: 1000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "DMMブックス",
            category: .manga,
            iconName: "purchased.circle",
            plans: [
                SubscriptionPlan(name: "月額コース", amount: 1100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Renta!",
            category: .manga,
            iconName: "arrow.left.and.right.righttriangle.left.righttriangle.right",
            plans: [
                SubscriptionPlan(name: "月額1000ポイント", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "月額2000ポイント", amount: 2200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "マンガワン",
            category: .manga,
            iconName: "heart.text.square.fill",
            plans: [
                SubscriptionPlan(name: "月額ショップ定額", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "マンガUP!",
            category: .manga,
            iconName: "arrow.up.circle",
            plans: [
                SubscriptionPlan(name: "月額定額", amount: 980, billingCycle: .monthly)
            ]
        ),

        // MARK: - スポーツ (Sports) - 12件
        SubscriptionPreset(
            name: "DAZN",
            category: .sports,
            iconName: "sportscourt",
            plans: [
                SubscriptionPlan(name: "Standard(月額)", amount: 4200, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard(年間/月々払い)", amount: 3200, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard(年間/一括)", amount: 32000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "パ・リーグTV",
            category: .sports,
            iconName: "sportscourt.fill",
            plans: [
                SubscriptionPlan(name: "一般会員(月額)", amount: 1595, billingCycle: .monthly),
                SubscriptionPlan(name: "ファンクラブ会員(月額)", amount: 1045, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "スカパー! プロ野球セット",
            category: .sports,
            iconName: "baseball",
            plans: [
                SubscriptionPlan(name: "月額プラン(基本料含む)", amount: 4483, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "J SPORTS オンデマンド",
            category: .sports,
            iconName: "figure.run.square.stack",
            plans: [
                SubscriptionPlan(name: "総合パック", amount: 2640, billingCycle: .monthly),
                SubscriptionPlan(name: "U25割 総合パック", amount: 1320, billingCycle: .monthly),
                SubscriptionPlan(name: "野球パック", amount: 1980, billingCycle: .monthly),
                SubscriptionPlan(name: "ラグビーパック", amount: 1980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "虎テレ (阪神タイガース)",
            category: .sports,
            iconName: "pawprint",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 660, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ホークスTV",
            category: .sports,
            iconName: "bird",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 550, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "GIANTS TV",
            category: .sports,
            iconName: "figure.baseball",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1320, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "バスケットLIVE",
            category: .sports,
            iconName: "basketball",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 550, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 5500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "SPOTV NOW",
            category: .sports,
            iconName: "figure.soccer",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 3000, billingCycle: .monthly),
                SubscriptionPlan(name: "年間パス", amount: 27000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "新日本プロレスワールド",
            category: .sports,
            iconName: "trophy",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1298, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "WRESTLE UNIVERSE",
            category: .sports,
            iconName: "trophy.fill",
            plans: [
                SubscriptionPlan(name: "月額会員", amount: 1280, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "T.LEAGUE TV (卓球)",
            category: .sports,
            iconName: "circle.grid.cross",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 500, billingCycle: .monthly)
            ]
        ),

        // MARK: - ゲーム (Game) - 9件
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
            iconName: "gamecontroller.fill",
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
        SubscriptionPreset(
            name: "Apple Arcade",
            category: .game,
            iconName: "arcade.stick",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 900, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "EA Play",
            category: .game,
            iconName: "star.square",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 600, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 4180, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Ubisoft+",
            category: .game,
            iconName: "sparkles",
            plans: [
                SubscriptionPlan(name: "Classics(月額)", amount: 800, billingCycle: .monthly),
                SubscriptionPlan(name: "Premium(月額)", amount: 2500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "GeForce NOW",
            category: .game,
            iconName: "cpu.fill",
            plans: [
                SubscriptionPlan(name: "Priority(月額)", amount: 1790, billingCycle: .monthly),
                SubscriptionPlan(name: "Ultimate(月額)", amount: 3560, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Google Play Pass",
            category: .game,
            iconName: "play.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 600, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 5400, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "PC Game Pass",
            category: .game,
            iconName: "desktopcomputer",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 990, billingCycle: .monthly)
            ]
        ),

        // MARK: - 子育て・キッズ (Kids) - 12件
        SubscriptionPreset(
            name: "こどもちゃれんじ",
            category: .kids,
            iconName: "figure.2.and.child.holdinghands",
            plans: [
                SubscriptionPlan(name: "月々払い(目安)", amount: 2990, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "スマイルゼミ",
            category: .kids,
            iconName: "ipad.and.arrow.forward",
            plans: [
                SubscriptionPlan(name: "幼児コース(月額)", amount: 3278, billingCycle: .monthly),
                SubscriptionPlan(name: "小学1年生(月額)", amount: 3828, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Z会 幼児コース",
            category: .kids,
            iconName: "doc.text.fill",
            plans: [
                SubscriptionPlan(name: "年少(月々払い)", amount: 2420, billingCycle: .monthly),
                SubscriptionPlan(name: "年中(月々払い)", amount: 2890, billingCycle: .monthly),
                SubscriptionPlan(name: "年長(月々払い)", amount: 3100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "チャレンジタッチ (進研ゼミ)",
            category: .kids,
            iconName: "laptopcomputer.and.arrow.outline.right",
            plans: [
                SubscriptionPlan(name: "小学1年生(月々払い)", amount: 4020, billingCycle: .monthly),
                SubscriptionPlan(name: "小学6年生(月々払い)", amount: 6980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Amazon Kids+",
            category: .kids,
            iconName: "face.smiling",
            plans: [
                SubscriptionPlan(name: "プライム会員(月額)", amount: 480, billingCycle: .monthly),
                SubscriptionPlan(name: "一般会員(月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "プライム会員(年額)", amount: 4800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "幼児ポピー",
            category: .kids,
            iconName: "graduationcap.fill",
            plans: [
                SubscriptionPlan(name: "月々払い", amount: 1500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "RISU算数",
            category: .kids,
            iconName: "plus.minus.and.percent",
            plans: [
                SubscriptionPlan(name: "基本料(年一括換算月額分)", amount: 2750, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "トイサブ！ (知育玩具定期便)",
            category: .kids,
            iconName: "gift",
            plans: [
                SubscriptionPlan(name: "隔月お届けコース(月額換算)", amount: 3674, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Cha Cha Cha (おもちゃサブスク)",
            category: .kids,
            iconName: "gift.fill",
            plans: [
                SubscriptionPlan(name: "基本プラン", amount: 3630, billingCycle: .monthly),
                SubscriptionPlan(name: "学研ステイフル監修プラン", amount: 4950, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "And Toybox (おもちゃサブスク)",
            category: .kids,
            iconName: "shippingbox.fill",
            plans: [
                SubscriptionPlan(name: "スタンダードコース", amount: 3278, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアムコース", amount: 3608, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "絵本ナビ プレミアム",
            category: .kids,
            iconName: "books.vertical.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 580, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 5800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "dキッズ",
            category: .kids,
            iconName: "face.smiling.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 402, billingCycle: .monthly)
            ]
        ),

        // MARK: - ファンクラブ (Fanclub) - 10件
        SubscriptionPreset(
            name: "pixivFANBOX",
            category: .fanclub,
            iconName: "star.circle.fill",
            plans: [
                SubscriptionPlan(name: "支援プランA", amount: 100, billingCycle: .monthly),
                SubscriptionPlan(name: "支援プランB", amount: 500, billingCycle: .monthly),
                SubscriptionPlan(name: "支援プランC", amount: 1000, billingCycle: .monthly),
                SubscriptionPlan(name: "支援プランD", amount: 3000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Fantia (ファンティア)",
            category: .fanclub,
            iconName: "heart.circle",
            plans: [
                SubscriptionPlan(name: "支援ファンクラブ(一般)", amount: 500, billingCycle: .monthly),
                SubscriptionPlan(name: "支援ファンクラブ(限定)", amount: 1000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Patreon",
            category: .fanclub,
            iconName: "heart.circle.fill",
            plans: [
                SubscriptionPlan(name: "Tier 1 ($5)", amount: 750, billingCycle: .monthly),
                SubscriptionPlan(name: "Tier 2 ($10)", amount: 1500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Twitch サブスク",
            category: .fanclub,
            iconName: "video.fill",
            plans: [
                SubscriptionPlan(name: "ティア 1", amount: 600, billingCycle: .monthly),
                SubscriptionPlan(name: "ティア 2", amount: 1200, billingCycle: .monthly),
                SubscriptionPlan(name: "ティア 3", amount: 2950, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "YouTube メンバーシップ",
            category: .fanclub,
            iconName: "person.crop.rectangle.stack",
            plans: [
                SubscriptionPlan(name: "メンバーシップ枠A", amount: 490, billingCycle: .monthly),
                SubscriptionPlan(name: "メンバーシップ枠B", amount: 990, billingCycle: .monthly),
                SubscriptionPlan(name: "メンバーシップ枠C", amount: 2990, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Ci-en (シエン)",
            category: .fanclub,
            iconName: "arrow.up.heart",
            plans: [
                SubscriptionPlan(name: "月額プラン(支援)", amount: 500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "fanicon (ファニコン)",
            category: .fanclub,
            iconName: "person.3.sequence",
            plans: [
                SubscriptionPlan(name: "通常プラン", amount: 500, billingCycle: .monthly),
                SubscriptionPlan(name: "特別プラン", amount: 1000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ニコニコチャンネルプラス",
            category: .fanclub,
            iconName: "tv.and.mediabox",
            plans: [
                SubscriptionPlan(name: "月額会員プラン", amount: 550, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム会員", amount: 1100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "SHOWROOM プレミアムライブ",
            category: .fanclub,
            iconName: "video.badge.plus",
            plans: [
                SubscriptionPlan(name: "月額定期枠", amount: 500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "FANTS (ファンツ)",
            category: .fanclub,
            iconName: "person.crop.circle.badge.checkmark",
            plans: [
                SubscriptionPlan(name: "サロン月額プラン", amount: 1000, billingCycle: .monthly)
            ]
        ),

        // MARK: - 学習・教育 (Education) - 16件
        SubscriptionPreset(
            name: "スタディサプリ",
            category: .education,
            iconName: "graduationcap",
            plans: [
                SubscriptionPlan(name: "高校・大学受験ベーシック", amount: 2178, billingCycle: .monthly),
                SubscriptionPlan(name: "TOEIC L&R TEST対策", amount: 3278, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "英単語アプリmikan",
            category: .education,
            iconName: "character.book.closed",
            plans: [
                SubscriptionPlan(name: "mikan PRO (月額)", amount: 1000, billingCycle: .monthly),
                SubscriptionPlan(name: "mikan PRO (年額)", amount: 7200, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Schoo (スクー)",
            category: .education,
            iconName: "video.square",
            plans: [
                SubscriptionPlan(name: "プレミアムプラン(月額)", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアムプラン(年額)", amount: 9800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "LinkedIn Learning",
            category: .education,
            iconName: "briefcase.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 4800, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン(月換算分)", amount: 3200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Progate",
            category: .education,
            iconName: "terminal.fill",
            plans: [
                SubscriptionPlan(name: "プラスプラン", amount: 1490, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "N予備校",
            category: .education,
            iconName: "books.vertical.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Duolingo",
            category: .education,
            iconName: "character.book.closed.fill",
            plans: [
                SubscriptionPlan(name: "Super Duolingo (月額)", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "Super Duolingo (年額)", amount: 9900, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Udemy 個人向け定額",
            category: .education,
            iconName: "play.rectangle.fill",
            plans: [
                SubscriptionPlan(name: "個人向け定額サブスクリプション", amount: 2600, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "NativeCamp (ネイティブキャンプ)",
            category: .education,
            iconName: "phone.bubble.left.fill",
            plans: [
                SubscriptionPlan(name: "プレミアムプラン(レッスン無制限)", amount: 6480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "DMM英会話",
            category: .education,
            iconName: "megaphone.fill",
            plans: [
                SubscriptionPlan(name: "スタンダードプラン(毎日1回)", amount: 7900, billingCycle: .monthly),
                SubscriptionPlan(name: "プラスネイティブ(毎日1回)", amount: 19800, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "レアジョブ英会話",
            category: .education,
            iconName: "bubble.left.and.bubble.right.fill",
            plans: [
                SubscriptionPlan(name: "日常英会話(毎日25分)", amount: 7980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "abceed (英語AIアプリ)",
            category: .education,
            iconName: "brain.head.profile.fill",
            plans: [
                SubscriptionPlan(name: "Proプラン(月額)", amount: 2700, billingCycle: .monthly),
                SubscriptionPlan(name: "Proプラン(年額)", amount: 16800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "グロービス学び放題",
            category: .education,
            iconName: "bookmark.square.fill",
            plans: [
                SubscriptionPlan(name: "半年プラン(一括月換算)", amount: 1980, billingCycle: .monthly),
                SubscriptionPlan(name: "年間プラン(一括月換算)", amount: 1650, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "EnglishCentral",
            category: .education,
            iconName: "globe",
            plans: [
                SubscriptionPlan(name: "プレミアム(月額)", amount: 3278, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "SANTA L&R (AI TOEIC)",
            category: .education,
            iconName: "doc.text.magnifyingglass",
            plans: [
                SubscriptionPlan(name: "定期購入(月々)", amount: 2900, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "資格スクエア",
            category: .education,
            iconName: "square.and.pencil",
            plans: [
                SubscriptionPlan(name: "月々定額プラン(目安)", amount: 9800, billingCycle: .monthly)
            ]
        ),

        // MARK: - 仕事・制作 (Work) - 20件
        SubscriptionPreset(
            name: "Notion",
            category: .work,
            iconName: "note.text",
            plans: [
                SubscriptionPlan(name: "Plus (月額払い$12)", amount: 1800, billingCycle: .monthly),
                SubscriptionPlan(name: "Plus (年額払い$10/月)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Notion AI アドオン ($10/月)", amount: 1500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Canva",
            category: .work,
            iconName: "paintpalette",
            plans: [
                SubscriptionPlan(name: "Canva Pro (月額)", amount: 1180, billingCycle: .monthly),
                SubscriptionPlan(name: "Canva Pro (年額)", amount: 12000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "AWS (Amazon Web Services)",
            category: .work,
            iconName: "server.rack",
            plans: [
                SubscriptionPlan(name: "個人開発・検証目安", amount: 2000, billingCycle: .monthly),
                SubscriptionPlan(name: "個人開発・検証目安(高負荷)", amount: 5000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "n8n Cloud",
            category: .work,
            iconName: "flowchart",
            plans: [
                SubscriptionPlan(name: "Starter", amount: 3200, billingCycle: .monthly)
            ]
        ),
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
            name: "Figma",
            category: .work,
            iconName: "square.filled.on.square.filled",
            plans: [
                SubscriptionPlan(name: "Professional(月額)", amount: 2250, billingCycle: .monthly),
                SubscriptionPlan(name: "Professional(年額)", amount: 22500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Asana",
            category: .work,
            iconName: "checklist",
            plans: [
                SubscriptionPlan(name: "Starter(月々)", amount: 1400, billingCycle: .monthly),
                SubscriptionPlan(name: "Advanced(月々)", amount: 3300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Grammarly",
            category: .work,
            iconName: "text.justify.left",
            plans: [
                SubscriptionPlan(name: "Premium(月額)", amount: 4500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Loom",
            category: .work,
            iconName: "video.badge.checkmark",
            plans: [
                SubscriptionPlan(name: "Business(月額)", amount: 1800, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Miro",
            category: .work,
            iconName: "rectangle.3.group",
            plans: [
                SubscriptionPlan(name: "Starter(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Business(月額)", amount: 3000, billingCycle: .monthly)
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
            name: "Trello",
            category: .work,
            iconName: "sidebar.left",
            plans: [
                SubscriptionPlan(name: "Standard(月額)", amount: 750, billingCycle: .monthly),
                SubscriptionPlan(name: "Premium(月額)", amount: 1500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Evernote",
            category: .work,
            iconName: "paperclip",
            plans: [
                SubscriptionPlan(name: "Personal(月額)", amount: 1100, billingCycle: .monthly),
                SubscriptionPlan(name: "Professional(月額)", amount: 1550, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "DeepL Pro",
            category: .work,
            iconName: "character",
            plans: [
                SubscriptionPlan(name: "Starter(月額)", amount: 1200, billingCycle: .monthly),
                SubscriptionPlan(name: "Advanced(月額)", amount: 3800, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "GitHub",
            category: .work,
            iconName: "keyboard",
            plans: [
                SubscriptionPlan(name: "Copilot Individual(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Copilot Individual(年額)", amount: 15000, billingCycle: .yearly),
                SubscriptionPlan(name: "Pro(月額)", amount: 600, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "JetBrains Toolbox",
            category: .work,
            iconName: "square.grid.3x3.fill",
            plans: [
                SubscriptionPlan(name: "All Products Pack(月額)", amount: 4200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Sketch",
            category: .work,
            iconName: "diamond",
            plans: [
                SubscriptionPlan(name: "Standard(月額)", amount: 1350, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Todoist",
            category: .work,
            iconName: "checklist.checked",
            plans: [
                SubscriptionPlan(name: "Pro(月額)", amount: 550, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro(年額)", amount: 5300, billingCycle: .yearly)
            ]
        ),

        // MARK: - 生成AI (Generative AI) - 10件
        SubscriptionPreset(
            name: "ChatGPT",
            category: .ai,
            iconName: "brain.head.profile",
            plans: [
                SubscriptionPlan(name: "ChatGPT Plus ($20/月)", amount: 3000, billingCycle: .monthly),
                SubscriptionPlan(name: "ChatGPT Team ($30/月)", amount: 4500, billingCycle: .monthly),
                SubscriptionPlan(name: "ChatGPT Pro ($200/月)", amount: 30000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Gemini (Google One AI)",
            category: .ai,
            iconName: "sparkles",
            plans: [
                SubscriptionPlan(name: "Google One AI Plus (200GB)", amount: 1300, billingCycle: .monthly),
                SubscriptionPlan(name: "Google One AI Premium (2TB)", amount: 2900, billingCycle: .monthly),
                SubscriptionPlan(name: "Google AI Ultra 5x ($100/月)", amount: 15500, billingCycle: .monthly),
                SubscriptionPlan(name: "Google AI Ultra 20x ($200/月)", amount: 31000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Claude",
            category: .ai,
            iconName: "cpu",
            plans: [
                SubscriptionPlan(name: "Claude Pro ($20/月)", amount: 3100, billingCycle: .monthly),
                SubscriptionPlan(name: "Claude Team ($30/月)", amount: 4650, billingCycle: .monthly),
                SubscriptionPlan(name: "Claude Max 5x ($100/月)", amount: 15500, billingCycle: .monthly),
                SubscriptionPlan(name: "Claude Max 20x ($200/月)", amount: 31000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Perplexity",
            category: .ai,
            iconName: "magnifyingglass.circle",
            plans: [
                SubscriptionPlan(name: "Pro (月額$20)", amount: 3100, billingCycle: .monthly),
                SubscriptionPlan(name: "Pro (年額$200)", amount: 31000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Midjourney",
            category: .ai,
            iconName: "photo.on.rectangle.angled",
            plans: [
                SubscriptionPlan(name: "Basic Plan ($10)", amount: 1550, billingCycle: .monthly),
                SubscriptionPlan(name: "Standard Plan ($30)", amount: 4650, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Copilot Pro",
            category: .ai,
            iconName: "sparkles.rectangle.stack",
            plans: [
                SubscriptionPlan(name: "Proプラン(月額)", amount: 3200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Cursor Pro",
            category: .ai,
            iconName: "terminal.fill",
            plans: [
                SubscriptionPlan(name: "Pro ($20/月)", amount: 3100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Runway Gen-2",
            category: .ai,
            iconName: "video.fill",
            plans: [
                SubscriptionPlan(name: "Standard ($15/月)", amount: 2320, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "v0 by Vercel",
            category: .ai,
            iconName: "shippingbox",
            plans: [
                SubscriptionPlan(name: "Premium ($20/月)", amount: 3100, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Poe Pro",
            category: .ai,
            iconName: "message.fill",
            plans: [
                SubscriptionPlan(name: "Pro ($20/月)", amount: 3100, billingCycle: .monthly)
            ]
        ),

        // MARK: - ニュース・読書 (News) - 15件
        SubscriptionPreset(
            name: "Kindle Unlimited",
            category: .news,
            iconName: "book",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "日経電子版",
            category: .news,
            iconName: "newspaper",
            plans: [
                SubscriptionPlan(name: "日経電子版(月額)", amount: 4277, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "楽天マガジン",
            category: .news,
            iconName: "magazine",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 418, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 3960, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Amazon Audible",
            category: .news,
            iconName: "headphones",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "flier (フライヤー)",
            category: .news,
            iconName: "books.vertical.fill",
            plans: [
                SubscriptionPlan(name: "ゴールドプラン(月額)", amount: 2200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "朝日新聞デジタル",
            category: .news,
            iconName: "doc.text.fill",
            plans: [
                SubscriptionPlan(name: "シンプルコース", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "ダブルコース", amount: 4900, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "audiobook.jp",
            category: .news,
            iconName: "headphones.circle",
            plans: [
                SubscriptionPlan(name: "聴き放題プラン(月額)", amount: 1330, billingCycle: .monthly),
                SubscriptionPlan(name: "聴き放題プラン(年額)", amount: 9900, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "dマガジン",
            category: .news,
            iconName: "magazine.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 440, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "毎日新聞デジタル",
            category: .news,
            iconName: "doc.text.image.fill",
            plans: [
                SubscriptionPlan(name: "スタンダードコース", amount: 1078, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "産経電子版",
            category: .news,
            iconName: "doc.plaintext",
            plans: [
                SubscriptionPlan(name: "産経新聞(月額)", amount: 1980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "現代ビジネス プレミアム",
            category: .news,
            iconName: "newspaper.fill",
            plans: [
                SubscriptionPlan(name: "月額会員", amount: 880, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "東洋経済オンライン プレミアム",
            category: .news,
            iconName: "doc.richtext.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 2000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "プレジデントオンライン プレミアム",
            category: .news,
            iconName: "chart.bar.doc.horizontal.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 880, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "NewsPicks",
            category: .news,
            iconName: "newspaper",
            plans: [
                SubscriptionPlan(name: "プレミアム(月額)", amount: 1700, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(年額)", amount: 17000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "日経ビジネス電子版",
            category: .news,
            iconName: "chart.line.uptrend.xyaxis",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 2500, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 25000, billingCycle: .yearly)
            ]
        ),

        // MARK: - クラウド (Cloud) - 10件
        SubscriptionPreset(
            name: "iCloud+",
            category: .cloud,
            iconName: "cloud",
            plans: [
                SubscriptionPlan(name: "50GB", amount: 130, billingCycle: .monthly),
                SubscriptionPlan(name: "200GB", amount: 450, billingCycle: .monthly),
                SubscriptionPlan(name: "2TB", amount: 1300, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Google One",
            category: .cloud,
            iconName: "externaldrive",
            plans: [
                SubscriptionPlan(name: "ベーシック(100GB)", amount: 250, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード(200GB)", amount: 380, billingCycle: .monthly),
                SubscriptionPlan(name: "プレミアム(2TB)", amount: 1300, billingCycle: .monthly),
                SubscriptionPlan(name: "ベーシック(100GB年額)", amount: 2500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Dropbox",
            category: .cloud,
            iconName: "shippingbox",
            plans: [
                SubscriptionPlan(name: "Plus(月額)", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "Plus(年額)", amount: 14400, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "OneDrive",
            category: .cloud,
            iconName: "cloud.fill",
            plans: [
                SubscriptionPlan(name: "Microsoft 365 Basic (100GB)", amount: 260, billingCycle: .monthly),
                SubscriptionPlan(name: "Microsoft 365 Basic (100GB年額)", amount: 2440, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Box",
            category: .cloud,
            iconName: "archivebox",
            plans: [
                SubscriptionPlan(name: "Personal Pro (100GB)", amount: 1200, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Backblaze",
            category: .cloud,
            iconName: "externaldrive.badge.icloud",
            plans: [
                SubscriptionPlan(name: "個人バックアップ(月額 $9)", amount: 1350, billingCycle: .monthly),
                SubscriptionPlan(name: "個人バックアップ(年額)", amount: 14850, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "pCloud",
            category: .cloud,
            iconName: "lock.icloud",
            plans: [
                SubscriptionPlan(name: "Premium 500GB ($4.99)", amount: 780, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "MEGA",
            category: .cloud,
            iconName: "icloud.circle",
            plans: [
                SubscriptionPlan(name: "Pro I (2TB)", amount: 1560, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "TeraBox",
            category: .cloud,
            iconName: "icloud.and.arrow.up",
            plans: [
                SubscriptionPlan(name: "プレミアム(2TB)", amount: 380, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "IDrive",
            category: .cloud,
            iconName: "externaldrive.connected.to.line.below",
            plans: [
                SubscriptionPlan(name: "Personal (年額目安)", amount: 11000, billingCycle: .yearly)
            ]
        ),

        // MARK: - セキュリティ (Security) - 8件
        SubscriptionPreset(
            name: "1Password",
            category: .security,
            iconName: "key",
            plans: [
                SubscriptionPlan(name: "個人(月額)", amount: 450, billingCycle: .monthly),
                SubscriptionPlan(name: "ファミリー(月額)", amount: 750, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Norton 360",
            category: .security,
            iconName: "shield",
            plans: [
                SubscriptionPlan(name: "デラックス(月額換算目安)", amount: 600, billingCycle: .monthly),
                SubscriptionPlan(name: "デラックス(年額版)", amount: 7200, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "NordVPN",
            category: .security,
            iconName: "lock.shield",
            plans: [
                SubscriptionPlan(name: "スタンダード(月々払い)", amount: 1970, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダード(1年プラン月換算)", amount: 680, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "McAfee リブセーフ",
            category: .security,
            iconName: "shield.fill",
            plans: [
                SubscriptionPlan(name: "年額プラン(月換算目安)", amount: 800, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン(一括)", amount: 9600, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "ExpressVPN",
            category: .security,
            iconName: "lock.rectangle",
            plans: [
                SubscriptionPlan(name: "1ヶ月プラン ($12.95)", amount: 1950, billingCycle: .monthly),
                SubscriptionPlan(name: "12ヶ月プラン ($8.32/月)", amount: 1250, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Bitwarden",
            category: .security,
            iconName: "key.fill",
            plans: [
                SubscriptionPlan(name: "プレミアム会員(年額$10相当)", amount: 1500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Surfshark VPN",
            category: .security,
            iconName: "checkmark.shield",
            plans: [
                SubscriptionPlan(name: "月々プラン", amount: 1750, billingCycle: .monthly),
                SubscriptionPlan(name: "12ヶ月プラン(月換算)", amount: 500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ウイルスバスター クラウド",
            category: .security,
            iconName: "shield.lefthalf.filled",
            plans: [
                SubscriptionPlan(name: "月額会員", amount: 518, billingCycle: .monthly),
                SubscriptionPlan(name: "1年版(一括)", amount: 5720, billingCycle: .yearly)
            ]
        ),

        // MARK: - ヘルスケア (Healthcare) - 12件
        SubscriptionPreset(
            name: "エニタイムフィットネス",
            category: .healthcare,
            iconName: "figure.run",
            plans: [
                SubscriptionPlan(name: "月額プラン(店舗により異なる)", amount: 7480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "chocoZAP (チョコザップ)",
            category: .healthcare,
            iconName: "figure.walk",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 3278, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "JOYFIT24",
            category: .healthcare,
            iconName: "figure.run.circle",
            plans: [
                SubscriptionPlan(name: "ナショナル会員(月額)", amount: 7678, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Apple Fitness+",
            category: .healthcare,
            iconName: "appletv.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 980, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 4800, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "LEAN BODY (リーンボディ)",
            category: .healthcare,
            iconName: "figure.mind.and.body",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1480, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン(一括月換算)", amount: 980, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "FiNC プレミアム",
            category: .healthcare,
            iconName: "heart.text.square",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 960, billingCycle: .monthly)
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
            name: "カーブス (Curves)",
            category: .healthcare,
            iconName: "figure.dance",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 6820, billingCycle: .monthly),
                SubscriptionPlan(name: "年割プラン(月々)", amount: 5720, billingCycle: .monthly)
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
            name: "あすけん プレミアム",
            category: .healthcare,
            iconName: "fork.knife.circle",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 480, billingCycle: .monthly),
                SubscriptionPlan(name: "半年プラン", amount: 1900, billingCycle: .monthly),
                SubscriptionPlan(name: "年間プラン", amount: 3600, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Calm (マインドフルネス)",
            category: .healthcare,
            iconName: "wind",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 970, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 6500, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Headspace",
            category: .healthcare,
            iconName: "brain",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 1500, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 10000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "ルナルナ",
            category: .healthcare,
            iconName: "heart.text.square",
            plans: [
                SubscriptionPlan(name: "プレミアムコース", amount: 400, billingCycle: .monthly)
            ]
        ),

        // MARK: - フード・宅配 (Food) - 12件
        SubscriptionPreset(
            name: "DREAMBEER",
            category: .food,
            iconName: "mug.fill",
            plans: [
                SubscriptionPlan(name: "クラフトビール定期購入パック目安", amount: 10000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ウォーターサーバー",
            category: .food,
            iconName: "drop.fill",
            plans: [
                SubscriptionPlan(name: "標準プラン(お水2本目安)", amount: 4000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Uber Eats One",
            category: .food,
            iconName: "cart.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 498, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 3998, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "Oisix (オイシックス)",
            category: .food,
            iconName: "carrot",
            plans: [
                SubscriptionPlan(name: "定期宅配目安(月換算分)", amount: 20000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "らでぃっしゅぼーや",
            category: .food,
            iconName: "leaf",
            plans: [
                SubscriptionPlan(name: "定期宅配目安(月換算分)", amount: 15000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "nosh (ナッシュ)",
            category: .food,
            iconName: "bag",
            plans: [
                SubscriptionPlan(name: "10食定期便(1回分目安)", amount: 5990, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ウェルネスダイニング",
            category: .food,
            iconName: "bag.fill",
            plans: [
                SubscriptionPlan(name: "制限食弁当(7食定期)", amount: 4968, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ヨシケイ (ミールキット)",
            category: .food,
            iconName: "cart.badge.plus",
            plans: [
                SubscriptionPlan(name: "夕食ネット目安(月換算)", amount: 25000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Base Food (ベースフード)",
            category: .food,
            iconName: "birthday.cake",
            plans: [
                SubscriptionPlan(name: "継続コース目安(月額分)", amount: 4000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "三ツ星ファーム",
            category: .food,
            iconName: "fork.knife",
            plans: [
                SubscriptionPlan(name: "7食コース定期便", amount: 5897, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "snaq.me (スナックミー)",
            category: .food,
            iconName: "cup.and.saucer",
            plans: [
                SubscriptionPlan(name: "おやつ定期便(1回目安)", amount: 2180, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "ブルーボトルコーヒー定期便",
            category: .food,
            iconName: "cup.and.saucer.fill",
            plans: [
                SubscriptionPlan(name: "定期便目安", amount: 3000, billingCycle: .monthly)
            ]
        ),

        // MARK: - ファイナンス (Financial) - 8件
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
                SubscriptionPlan(name: "個人向け スターター(月額)", amount: 1180, billingCycle: .monthly),
                SubscriptionPlan(name: "個人向け スターター(年額)", amount: 11760, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "弥生会計 オンライン",
            category: .financial,
            iconName: "square.grid.3x1.below.line.grid.1x2",
            plans: [
                SubscriptionPlan(name: "セルフプラン(月換算目安)", amount: 2000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Moneytree",
            category: .financial,
            iconName: "tree",
            plans: [
                SubscriptionPlan(name: "Moneytree Grow(月額)", amount: 360, billingCycle: .monthly),
                SubscriptionPlan(name: "Moneytree Work(月額)", amount: 500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "おかねのコンパス",
            category: .financial,
            iconName: "safari",
            plans: [
                SubscriptionPlan(name: "プレミアム(月額)", amount: 360, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "バフェット・コード",
            category: .financial,
            iconName: "chart.bar.xaxis",
            plans: [
                SubscriptionPlan(name: "プロプラン(月額)", amount: 5000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "TradingView",
            category: .financial,
            iconName: "chart.xyaxis.line",
            plans: [
                SubscriptionPlan(name: "Essential ($14.95)", amount: 2320, billingCycle: .monthly),
                SubscriptionPlan(name: "Plus ($29.95)", amount: 4640, billingCycle: .monthly),
                SubscriptionPlan(name: "Premium ($59.95)", amount: 9280, billingCycle: .monthly)
            ]
        ),

        // MARK: - ライフスタイル (Lifestyle) - 10件
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
            name: "Uber One",
            category: .lifestyle,
            iconName: "car.fill",
            plans: [
                SubscriptionPlan(name: "月額プラン", amount: 498, billingCycle: .monthly),
                SubscriptionPlan(name: "年額プラン", amount: 3998, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "メチャカリ (服レンタル)",
            category: .lifestyle,
            iconName: "tshirt",
            plans: [
                SubscriptionPlan(name: "ライトプラン", amount: 3278, billingCycle: .monthly),
                SubscriptionPlan(name: "ベーシックプラン", amount: 6380, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "airCloset (ファッションレンタル)",
            category: .lifestyle,
            iconName: "tshirt.fill",
            plans: [
                SubscriptionPlan(name: "ライトプラン", amount: 7800, billingCycle: .monthly),
                SubscriptionPlan(name: "レギュラープラン", amount: 10800, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "タスカジ (家事代行)",
            category: .lifestyle,
            iconName: "house",
            plans: [
                SubscriptionPlan(name: "家事代行スポット利用(1回目安)", amount: 7000, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "Laxus (高級バッグレンタル)",
            category: .lifestyle,
            iconName: "handbag",
            plans: [
                SubscriptionPlan(name: "定額レンタルプラン", amount: 7480, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "サマリーポケット (宅配収納)",
            category: .lifestyle,
            iconName: "shippingbox.circle",
            plans: [
                SubscriptionPlan(name: "エコノミープラン(1箱月額)", amount: 330, billingCycle: .monthly),
                SubscriptionPlan(name: "スタンダードプラン(1箱月額)", amount: 440, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "FLOWER (お花の定期便)",
            category: .lifestyle,
            iconName: "flower.earring",
            plans: [
                SubscriptionPlan(name: "ポストに届くプラン(隔週1回分)", amount: 880, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "BLOOMBOX (コスメ定期便)",
            category: .lifestyle,
            iconName: "heart.text.square.fill",
            plans: [
                SubscriptionPlan(name: "月々会員プラン", amount: 1650, billingCycle: .monthly)
            ]
        ),

        // MARK: - その他 (Other) - 3件
        SubscriptionPreset(
            name: "汎用月額プラン",
            category: .other,
            iconName: "ellipsis.circle",
            plans: [
                SubscriptionPlan(name: "月額1000円", amount: 1000, billingCycle: .monthly),
                SubscriptionPlan(name: "月額500円", amount: 500, billingCycle: .monthly)
            ]
        ),
        SubscriptionPreset(
            name: "汎用年額プラン",
            category: .other,
            iconName: "ellipsis.circle.fill",
            plans: [
                SubscriptionPlan(name: "年額10000円", amount: 10000, billingCycle: .yearly),
                SubscriptionPlan(name: "年額5000円", amount: 5000, billingCycle: .yearly)
            ]
        ),
        SubscriptionPreset(
            name: "カスタムプラン",
            category: .other,
            iconName: "pencil",
            plans: [
                SubscriptionPlan(name: "カスタム", amount: 0, billingCycle: .monthly)
            ]
        )
    ]
    
    /// カテゴリごとにプリセットをグループ化した辞書を返す
    static var groupedByCategory: [Category: [SubscriptionPreset]] {
        Dictionary(grouping: defaultPresets, by: { $0.category })
    }
}
