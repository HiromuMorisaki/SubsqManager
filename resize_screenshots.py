import os
from PIL import Image

def main():
    input_dir = "/Users/hiromu/work/dv/SubsqManager/AppStoreScreenshots"
    output_dir = "/Users/hiromu/work/dv/SubsqManager/AppStoreScreenshots_6.5inch"
    
    os.makedirs(output_dir, exist_ok=True)
    
    # 6.5インチ用の必須サイズ
    target_width = 1284
    target_height = 2778
    
    # 7枚のスクリーンショットに対応
    for i in range(1, 8):
        filename = f"Screenshot_{i}.png"
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)
        
        if not os.path.exists(input_path):
            continue
            
        try:
            img = Image.open(input_path)
            # アスペクト比がほぼ同じなので、そのままリサイズします
            resized_img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
            resized_img.save(output_path, "PNG")
            print(f"Saved 6.5 inch version: {output_path}")
        except Exception as e:
            print(f"Error processing {filename}: {e}")

if __name__ == "__main__":
    main()
