import os
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def draw_vertical_gradient(draw, width, height, top_color, bottom_color):
    """ピクセル単位で綺麗な非線形縦方向グラデーションを描画する
    イージング関数を適用して上部の暗い領域を広げ、テキストの絶対的可読性を保証しつつ、
    下部で鮮やかなネオングリーンを発光させるプレミアムなサイバーパンクスタイル。
    """
    for y in range(height):
        ratio = y / height
        # イージング（2乗）で遷移を変化させ、上部の暗い領域（テキスト部）を広く確保する
        adjusted_ratio = ratio ** 1.8
        
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * adjusted_ratio)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * adjusted_ratio)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * adjusted_ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

def create_screenshot(input_path, output_path, text, top_color, bottom_color):
    target_width = 1290
    target_height = 2796
    
    try:
        input_image = Image.open(input_path).convert("RGBA")
    except Exception as e:
        print(f"⚠️ ファイルオープン失敗 {input_path}: {e}")
        return False
        
    # ベースの背景画像を生成
    result_image = Image.new("RGBA", (target_width, target_height))
    draw = ImageDraw.Draw(result_image)
    
    # プレミアムな非線形グラデーション背景を描画
    draw_vertical_gradient(draw, target_width, target_height, top_color, bottom_color)
    
    # テキストフォントのロード（太字のヒラギノ角ゴシック W7 または AppleGothic）
    font_path = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"
    try:
        font = ImageFont.truetype(font_path, 72)  # ASO最適な視認性サイズ
    except Exception:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/AppleGothic.ttf", 72)
        except Exception:
            font = ImageFont.load_default()
            print("Using default font.")

    # キャッチコピーを上部に描画（白文字で視認性を100%確保）
    text_color = (255, 255, 255, 255)
    text_y = 230
    
    draw.multiline_text(
        (target_width / 2, text_y),
        text,
        fill=text_color,
        font=font,
        align="center",
        anchor="ma",
        spacing=28
    )
    
    # --- スクリーンショットのサイズ調整と被り防止安全ガード ---
    # 横幅の最大占有率
    width_scale = 0.80
    target_image_width = int(target_width * width_scale)
    
    # ユーザーの「違和感のない程度に横に広げる」という要望に応え、
    # 縦方向サイズを相対的に「0.96倍（約4%）」に微調整し、横長（太め）の黄金iPhone比率を実現
    aspect_stretch_factor = 0.96
    ratio = target_image_width / input_image.width
    target_image_height = int(input_image.height * ratio * aspect_stretch_factor)
    
    bezel_padding = 12
    framed_width = target_image_width + (bezel_padding * 2)
    framed_height = target_image_height + (bezel_padding * 2)
    
    # テキスト底辺の絶対安全限界（被らない限界を攻める設定）
    text_bottom_safe = 425
    bottom_margin = 135  # 縦幅が縮んだ分、デバイスを上に吸い寄せるために 90 から 135 に調整
    max_framed_height = target_height - text_bottom_safe - bottom_margin
    
    # 画像が高すぎてテキストに被る場合は、アスペクト比を維持したまま自動スケールダウン
    if framed_height > max_framed_height:
        scale_factor = max_framed_height / framed_height
        target_image_width = int(target_image_width * scale_factor)
        target_image_height = int(target_image_height * scale_factor)
        framed_width = target_image_width + (bezel_padding * 2)
        framed_height = target_image_height + (bezel_padding * 2)
        print(f"  💡 極限調整・自動安全スケール発動 ({input_path}): {scale_factor:.2f}倍 に微小縮小")
    
    resized_img = input_image.resize((target_image_width, target_image_height), Image.Resampling.LANCZOS)
    
    # スマートフォンのデバイスフレーム風に角丸を切り抜く
    corner_radius = 52
    mask = Image.new("L", (target_image_width, target_image_height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, target_image_width, target_image_height), corner_radius, fill=255)
    
    # 擬似的な黒ベゼルフレームを追加して高級感を演出
    # ベゼル画像を作成 (Slate 900)
    framed_img = Image.new("RGBA", (framed_width, framed_height), (15, 23, 42, 255))
    
    # ベゼル画像自体のエッジに極細の発光ハイライトを施す (Vibrant Bezel Edge)
    framed_draw = ImageDraw.Draw(framed_img)
    highlight_color = (16, 185, 129, 90) # 不透明度約35%のネオングリーン
    framed_draw.rounded_rectangle(
        (0, 0, framed_width, framed_height),
        corner_radius + bezel_padding,
        outline=highlight_color,
        width=3
    )
    
    # ベゼル内部にスクショを角丸で切り抜いて貼り付け
    framed_img.paste(resized_img, (bezel_padding, bezel_padding), mask)
    
    # ベゼルのためのマスク
    framed_mask = Image.new("L", (framed_width, framed_height), 0)
    framed_mask_draw = ImageDraw.Draw(framed_mask)
    framed_mask_draw.rounded_rectangle((0, 0, framed_width, framed_height), corner_radius + bezel_padding, fill=255)
    
    # 配置座標の計算（画面下部にマージンをとって配置）
    img_x = (target_width - framed_width) // 2
    img_y = target_height - framed_height - bottom_margin
    
    # --- プレミアムな GaussianBlur ドロップシャドウの実装 ---
    shadow_offset_y = 35
    shadow_offset_x = 0
    shadow_blur = 32
    
    # シャドウ用キャンバス（透明）を作成
    shadow_canvas = Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))
    shadow_canvas_draw = ImageDraw.Draw(shadow_canvas)
    
    # ぼかしの元になる影を描画（不透明度約55%のブラック）
    shadow_canvas_draw.rounded_rectangle(
        (
            img_x + shadow_offset_x, 
            img_y + shadow_offset_y, 
            img_x + framed_width + shadow_offset_x, 
            img_y + framed_height + shadow_offset_y
        ),
        corner_radius + bezel_padding,
        fill=(5, 15, 12, 140)
    )
    
    # GaussianBlur で高品質なソフトシャドウに変換
    blurred_shadow = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow_blur))
    
    # 背景画像に影を重ねる
    result_image = Image.alpha_composite(result_image, blurred_shadow)
    
    # スクショ（ベゼル枠付き）を重ねる
    result_image.paste(framed_img, (img_x, img_y), framed_mask)
    
    # RGBに変換して保存
    final_image = result_image.convert("RGB")
    final_image.save(output_path, "PNG")
    print(f"✅ 生成完了: {output_path}")
    return True

def main():
    input_dir = "./RawScreenshots"
    output_dir = "./AppStoreScreenshots"
    
    os.makedirs(output_dir, exist_ok=True)
    
    # コテサクのNeon Greenブランドイメージにマッチしたプレミアムなグラデーションカラー
    # Top: 超ディープブラックグリーン（テキスト可読性確保のための深い闇）
    # Bottom: 鮮やかなエメラルド/ネオングリーン（ASOで最高に映えるブランドカラー）
    top_color = (6, 16, 14)        # #06100E (Deep Cyberpunk Forest)
    bottom_color = (16, 185, 129)  # #10B981 (Vibrant Neon Green)
    
    # ユーザーの素晴らしい構成案に基づく「黄金の7枚ストーリー」マッピング
    mapping = [
        ("shot_1.png", "人気サービスが勢揃い！\nあなたのお気に入りもすぐに見つかる"),
        ("shot_2.png", "スクショで一瞬！\n一括自動登録でタイパ最強"),
        ("shot_3.png", "直感フリックで断捨離。\n月1回のごほうび見直しデー"),
        ("shot_4.png", "解約忘れをゼロに。\nホーム画面でいつでも可視化"),
        ("shot_5.png", "自動でカレンダー同期。\n支払い管理を脳内から排除"),
        ("shot_6.png", "無駄な出費をあぶり出す！\nワクワクする削減・コスパ診断"),
        ("shot_7.png", "割り勘や経費も完璧。\n生活に寄り添うプロ仕様")
    ]
    
    # RawScreenshotsディレクトリの作成（存在しない場合）
    if not os.path.exists(input_dir):
        os.makedirs(input_dir)
        print(f"📁 '{input_dir}' ディレクトリを新規作成しました。ここにスクリーンショットを配置してください。")
        return
        
    # 最新の7枚のタイムスタンプ付きファイルを shot_1.png 〜 shot_7.png へ自動マッピングしてコピーする
    raw_mappings = {
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.29.29.png": "shot_1.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-28 at 23.58.15.png": "shot_2.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.27.34.png": "shot_3.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.20.35.png": "shot_4.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.25.21.png": "shot_5.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.28.37.png": "shot_6.png",
        "Simulator Screenshot - iPhone 17 Pro - 2026-05-29 at 12.28.15.png": "shot_7.png"
    }
    
    for orig, target in raw_mappings.items():
        orig_path = os.path.join(input_dir, orig)
        target_path = os.path.join(input_dir, target)
        if os.path.exists(orig_path):
            shutil.copy2(orig_path, target_path)
            print(f"🔄 自動マッピングコピー完了: {orig} -> {target}")
        
    success_count = 0
    for i, (filename, text) in enumerate(mapping):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, f"Screenshot_{i+1}.png")
        
        if os.path.exists(input_path):
            if create_screenshot(input_path, output_path, text, top_color, bottom_color):
                success_count += 1
        else:
            print(f"⚠️ スキップ: {input_path} が見つかりません。")
            
    if success_count > 0:
        print(f"🎉 計 {success_count} 枚の超プレミアムASOスクリーンショットを生成しました！")
    else:
        print("💡 RawScreenshotsの中に適切なシミュレータスクショを配置してからスクリプトを走らせてください。")

if __name__ == "__main__":
    main()
