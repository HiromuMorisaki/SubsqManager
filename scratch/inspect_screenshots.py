import os
import glob
from PIL import Image

def analyze_image(path):
    try:
        im = Image.open(path)
        # 画面中央付近と下部付近の色やパターンを調べる
        # 1206 x 2622 の解像度
        width, height = im.size
        
        # サブスクカレンダー: 3枚目 (緑の丸があるカレンダーか、iOS標準カレンダーの白・ダーク背景)
        # ウィジェット画面: 2枚目 (アプリアイコンやホーム画面のウィジェットが配置されている)
        # OCR一括登録: 1枚目 (インポートプレビューの紫ボタン)
        # 削減診断: 4枚目 (削減候補カード)
        # 経費・割り勘: 5枚目 (割り勘スライダーか、経費トグル)
        
        # 上部、中部、下部の代表ピクセル色を取得
        p_top = im.getpixel((width // 2, 200))
        p_mid = im.getpixel((width // 2, height // 2))
        p_bot = im.getpixel((width // 2, height - 200))
        
        # グレースケールに変換した領域統計などでさらに特徴を掴む
        print(f"File: {os.path.basename(path)}")
        print(f"  Size: {im.size}, Mode: {im.mode}")
        print(f"  Top pixel: {p_top}, Mid pixel: {p_mid}, Bot pixel: {p_bot}")
        
    except Exception as e:
        print(f"Error {path}: {e}")

def main():
    files = glob.glob('/Users/hiromu/work/dv/SubsqManager/RawScreenshots/*.png')
    for f in sorted(files):
        analyze_image(f)

if __name__ == "__main__":
    main()
