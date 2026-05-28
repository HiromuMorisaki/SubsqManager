import os
from PIL import Image, ImageDraw, ImageFont

def create_screenshot(input_path, output_path, text, bg_color):
    target_width = 1290
    target_height = 2796
    
    try:
        input_image = Image.open(input_path).convert("RGBA")
    except Exception as e:
        print(f"Failed to open {input_path}: {e}")
        return
        
    # Create background
    result_image = Image.new("RGBA", (target_width, target_height), bg_color)
    draw = ImageDraw.Draw(result_image)
    
    # Try to load a bold font
    font_path = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"
    try:
        font = ImageFont.truetype(font_path, 80) # Larger font
    except Exception:
        # Fallback
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/AppleGothic.ttf", 80)
        except:
            font = ImageFont.load_default()
            print("Using default font, text might not look good.")

    # Draw text at the top (centered)
    text_color = (30, 30, 30, 255)
    text_y = 180
    
    # Use multiline_text with 'ma' (middle-ascender) anchor to correctly center text and handle newlines
    draw.multiline_text(
        (target_width / 2, text_y),
        text,
        fill=text_color,
        font=font,
        align="center",
        anchor="ma",
        spacing=30 # Add space between lines
    )
    
    # Calculate image target size (make it slightly smaller to leave room for text)
    target_image_width = int(target_width * 0.80)
    ratio = target_image_width / input_image.width
    target_image_height = int(input_image.height * ratio)
    
    resized_img = input_image.resize((target_image_width, target_image_height), Image.Resampling.LANCZOS)
    
    # Create rounded corners for the screenshot
    mask = Image.new("L", (target_image_width, target_image_height), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = 60
    mask_draw.rounded_rectangle((0, 0, target_image_width, target_image_height), corner_radius, fill=255)
    
    # Paste image at the bottom center (reduce bottom margin to give more room at the top)
    img_x = (target_width - target_image_width) // 2
    img_y = target_height - target_image_height - 60 # 60px margin from bottom
    
    result_image.paste(resized_img, (img_x, img_y), mask)
    
    # Convert to RGB and save
    final_image = result_image.convert("RGB")
    final_image.save(output_path, "PNG")
    print(f"Saved {output_path}")

def main():
    input_dir = "/Users/hiromu/.gemini/antigravity/brain/58031870-4241-4f15-8755-1cb5ccc467a6"
    output_dir = "/Users/hiromu/work/dv/SubsqManager/AppStoreScreenshots"
    
    os.makedirs(output_dir, exist_ok=True)
    
    mapping = [
        ("media__1779689893984.png", "リストだけじゃない。\nカレンダーで見える化", (245, 248, 255, 255)),
        ("media__1779689986117.png", "直感的なスワイプで、\n無駄な出費を断捨離", (252, 245, 255, 255)),
        ("media__1779689959678.png", "今月、実際に支払う額を\n正確に把握。", (255, 246, 242, 255)),
        ("media__1779690045698.png", "スクショから自動読み取り\n面倒な入力なしで爆速登録", (245, 252, 248, 255))
    ]
    
    for i, (filename, text, bg_color) in enumerate(mapping):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, f"Screenshot_{i+1}.png")
        
        # Format text to align center line by line
        create_screenshot(input_path, output_path, text, bg_color)

if __name__ == "__main__":
    main()
