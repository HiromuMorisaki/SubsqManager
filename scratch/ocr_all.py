import os
import glob
import subprocess

def run_ocr(path):
    print(f"\n========================================\nAnalyzing: {os.path.basename(path)}")
    try:
        res = subprocess.run(
            ['swift', 'scratch/ocr_screenshot.swift', path],
            capture_output=True,
            text=True
        )
        output = res.stdout
        print(output)
        
        # 簡易自動判定
        out_lower = output.lower()
        if "一括登録" in output or "インポート" in output or "一括登録する" in output or "自動入力" in output:
            print("🌟 判定結果: [1枚目] スクショからの自動一括登録画面 (OCR)")
        elif "月額合計" in output and "削減実績" in output:
            print("🌟 判定結果: [2枚目] ホーム画面ウィジェット配置")
        elif "カレンダー" in output or "火" in output or "水" in output or "木" in output or "金" in output or "土" in output or "更新日" in output or "カレンダー連携" in output:
            if "次回の請求" in output and not "カレンダー" in output:
                # ウィジェットとかぶる場合があるため詳細を見る
                pass
            else:
                # iOSカレンダーの可能性が高い
                pass
        
    except Exception as e:
        print(f"Error {path}: {e}")

def main():
    files = glob.glob('/Users/hiromu/work/dv/SubsqManager/RawScreenshots/*.png')
    for f in sorted(files):
        run_ocr(f)

if __name__ == "__main__":
    main()
