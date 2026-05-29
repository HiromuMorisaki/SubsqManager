import os
import glob
from PIL import Image, ImageChops

def analyze(f):
    im = Image.open(f).convert("RGB")
    w, h = im.size
    
    # 色の統計情報を取得
    colors = im.getcolors(w * h)
    
    # 領域ごとの平均色
    # 上部 (ヘッダー部分)
    top_area = im.crop((0, 0, w, 200))
    top_colors = top_area.getcolors(w * 200)
    top_avg = tuple(map(int, [sum(x[1][i]*x[0] for x in top_colors)/sum(x[0] for x in top_colors) for i in range(3)]))
    
    # 中央部 (メインコンテンツ)
    mid_area = im.crop((0, 400, w, h - 400))
    mid_colors = mid_area.getcolors(w * (h - 800))
    mid_avg = tuple(map(int, [sum(x[1][i]*x[0] for x in mid_colors)/sum(x[0] for x in mid_colors) for i in range(3)]))
    
    print(f"File: {os.path.basename(f)}")
    print(f"  Top Avg Color: {top_avg}, Mid Avg Color: {mid_avg}")
    
    # 特徴判定
    # 1. カレンダー (iOS標準カレンダーは上が赤や白、全体的にカレンダーグリッドで白っぽい)
    # 2. ウィジェット画面 (iOSのホーム画面、背景がデフォルトブルー・ミントグラデーション、多数のアプリアイコン)
    # 3. コテサクアプリの画面 (コテサクは背景がほぼ黒/ダークテーマ。ヘッダーや背景が非常に暗い)
    # コテサクのダークテーマの平均色は極めて暗いはず (Mid Avg Color が極めて低い値、例えば 20以下)
    
    is_dark = mid_avg[0] < 45 and mid_avg[1] < 45 and mid_avg[2] < 45
    if is_dark:
        print("  -> App Screen (Dark Theme)")
        # アプリ内の個別画面の識別
        # - OCR一括インポート: 特徴的な紫色の「一括登録する」ボタンがあるはず
        # - 削減診断: 星マークや「削減候補」カードがある
        # - 経費/割り勘: 割り勘スライダーか、経費スイッチがある
    else:
        # ライトテーマまたはホーム画面
        # - ウィジェット画面: 壁紙がブルー/ミント (Top Avg: (26, 69, 155), Mid Avg: (172, 231, 218))
        if top_avg[0] < 50 and top_avg[2] > 100:
            print("  -> iOS Home Screen (Widgets Preview!)")
        else:
            print("  -> Light Screen (Calendar or other)")

def main():
    files = glob.glob('/Users/hiromu/work/dv/SubsqManager/RawScreenshots/*.png')
    for f in sorted(files):
        analyze(f)

if __name__ == "__main__":
    main()
