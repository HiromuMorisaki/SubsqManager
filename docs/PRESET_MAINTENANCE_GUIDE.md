# プリセットサブスクリプション メンテナンスガイド

> このドキュメントは `subscription_presets.json` の運用・更新手順をまとめたものです。

## 📁 ファイル構成

```
SubsqManager/
└── Resources/
    └── subscription_presets.json    ← プリセットデータ本体
```

## 📋 JSONフォーマット

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-05-29",
  "presets": [
    {
      "id": "spotify",
      "name": "Spotify",
      "category": "music",
      "iconName": "music.note",
      "plans": [
        {
          "id": "spotify_student",
          "name": "Student (学割)",
          "amount": 580,
          "billingCycle": "monthly"
        }
      ]
    }
  ]
}
```

## 🔑 フィールド定義

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `version` | String | SemVer形式（例: "1.1.0"）。データ変更時にバンプ |
| `lastUpdated` | String | 最終更新日（YYYY-MM-DD） |
| `presets[].id` | String | サービスの一意ID（snake_case）。**一度決めたら変更しない** |
| `presets[].name` | String | 表示名（日本語OK） |
| `presets[].category` | String | カテゴリ rawValue（後述の一覧参照） |
| `presets[].iconName` | String | SF Symbol名 |
| `presets[].plans[].id` | String | プランの一意ID（`{service_id}_{descriptor}`） |
| `presets[].plans[].name` | String | プラン名 |
| `presets[].plans[].amount` | Number | 金額（JPY） |
| `presets[].plans[].billingCycle` | String | `weekly` / `monthly` / `yearly` / `oneTime` |

## 🏷️ カテゴリ一覧

| rawValue | 表示名 | 用途 |
|----------|--------|------|
| `entertainment` | 動画・エンタメ | VOD、SNS課金 |
| `music` | 音楽 | 音楽ストリーミング |
| `manga` | マンガ・電子書籍 | マンガアプリ |
| `sports` | スポーツ | スポーツ配信 |
| `game` | ゲーム | ゲーム課金 |
| `kids` | 子育て・キッズ | 知育、おもちゃサブスク |
| `lessons` | 習い事・教室 | 塾、スイミング、音楽教室 |
| `fanclub` | ファンクラブ | クリエイター支援 |
| `education` | 学習・教育 | オンライン学習 |
| `work` | 仕事・制作 | SaaS、開発ツール |
| `ai` | 生成AI | AI系サービス |
| `news` | ニュース・読書 | 新聞、電子書籍 |
| `cloud` | クラウド | ストレージ |
| `security` | セキュリティ | VPN、パスワード管理 |
| `healthcare` | ヘルスケア | ジム、フィットネス |
| `food` | フード・宅配 | 食品定期便 |
| `financial` | ファイナンス | 家計簿、会計 |
| `lifestyle` | ライフスタイル | 日用品サブスク |
| `other` | その他 | 汎用テンプレート |

## 📝 更新手順

### 1. 価格変更
1. `subscription_presets.json` を開く
2. 対象サービスを検索（`id` または `name` で検索）
3. `amount` を新しい金額に変更
4. `version` をパッチバンプ（例: 1.0.0 → 1.0.1）
5. `lastUpdated` を更新

### 2. 新サービス追加
1. 以下のテンプレートをコピー:
```json
{
  "id": "新サービスのsnake_case_id",
  "name": "表示名",
  "category": "カテゴリrawValue",
  "iconName": "SF Symbol名",
  "plans": [
    {
      "id": "サービスid_プラン名",
      "name": "プラン表示名",
      "amount": 金額,
      "billingCycle": "monthly"
    }
  ]
}
```
2. 対応カテゴリセクションの末尾に挿入
3. `version` をマイナーバンプ（例: 1.0.1 → 1.1.0）

### 3. サービス終了時
- エントリ自体を削除するのではなく、`plans` を空配列にする方法を推奨
- 既存ユーザーの登録済みデータと名前が一致しなくなるのを防ぐため
- 必要に応じてコメントとして終了日を記録

### 4. サービス名変更
- `name` フィールドのみ変更
- `id` は**絶対に変更しない**（OCRマッチングやアナリティクスの整合性を維持するため）

### 5. 新カテゴリ追加
1. `Core/Models/Category.swift` に新しい case を追加
2. `displayName`, `iconName`, `color` の switch文に追加
3. JSONの `category` フィールドで新しい rawValue を使用開始
4. `PresetSelectionWizard` のカテゴリグリッド表示を確認

## ✅ 月次更新チェックリスト（毎月25日目安）

```
## v____ 更新 (YYYY/MM/DD)

- [ ] 主要サービスの値上げ・値下げ情報を確認
  - Netflix, YouTube Premium, DAZN, Spotify, Adobe CC
  - 参照: 各公式サイト、価格比較記事
- [ ] 新規人気サービスの追加検討
  - App Store ランキング、話題のサービスを確認
- [ ] サービス終了の確認・反映
- [ ] JSONの `version` バンプ
- [ ] JSONの `lastUpdated` 更新
- [ ] Xcodeでビルド確認（`xcodebuild build`）
- [ ] シミュレータで PresetSelectionWizard を起動確認
- [ ] App Store Connect へ新バージョン提出
```

## 🔍 バリデーション

ビルド前に以下を確認:

```bash
# JSONの構文チェック
python3 -c "import json; json.load(open('Resources/subscription_presets.json')); print('✅ Valid JSON')"

# プリセット件数確認
python3 -c "import json; d=json.load(open('Resources/subscription_presets.json')); print(f'プリセット数: {len(d[\"presets\"])}件')"

# ID重複チェック
python3 -c "
import json
d = json.load(open('Resources/subscription_presets.json'))
ids = [p['id'] for p in d['presets']]
plan_ids = [pl['id'] for p in d['presets'] for pl in p['plans']]
dup_preset = [x for x in ids if ids.count(x) > 1]
dup_plan = [x for x in plan_ids if plan_ids.count(x) > 1]
if dup_preset: print(f'⚠️ 重複プリセットID: {set(dup_preset)}')
elif dup_plan: print(f'⚠️ 重複プランID: {set(dup_plan)}')
else: print('✅ ID重複なし')
"
```

## 🔗 参照ファイル

| ファイル | 用途 |
|---------|------|
| `Core/Models/SubscriptionPreset.swift` | Codableモデル + PresetLoader |
| `Core/Models/Category.swift` | カテゴリenum定義 |
| `Core/Models/BillingCycle.swift` | 請求サイクルenum定義 |
| `Features/AddSubscription/Views/PresetSelectionWizard.swift` | プリセット選択UI |
| `Core/Services/OCRService.swift` | OCRマッチング（プリセット名で照合） |
