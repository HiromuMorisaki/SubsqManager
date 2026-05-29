import os
import subprocess
import json
from PIL import Image

# Directories
RAW_DIR = "/Users/hiromu/work/dv/SubsqManager/RawScreenshots/"
SCRATCH_DIR = "/Users/hiromu/work/dv/SubsqManager/scratch/"

os.makedirs(SCRATCH_DIR, exist_ok=True)

# Path to the swift helper code
SWIFT_OCR_CODE = """
import Foundation
import Vision
import AppKit

func recognizeText(in imagePath: String) {
    let url = URL(fileURLWithPath: imagePath)
    guard let image = NSImage(contentsOf: url),
          let tiffData = image.tiffRepresentation,
          let imageSource = CGImageSourceCreateWithData(tiffData as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("ERROR: Failed to load image \(imagePath)")
        return
    }
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            print(topCandidate.string)
        }
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    
    do {
        try requestHandler.perform([request])
    } catch {
        print("ERROR: Unable to perform OCR: \\(error)")
    }
}

let arguments = CommandLine.arguments
if arguments.count > 1 {
    let path = arguments[1]
    recognizeText(in: path)
} else {
    print("ERROR: No path specified")
}
"""

swift_script_path = os.path.join(SCRATCH_DIR, "ocr_helper.swift")
with open(swift_script_path, "w") as f:
    f.write(SWIFT_OCR_CODE)

print(f"Created Swift OCR helper at: {swift_script_path}")

screenshots = [f for f in os.listdir(RAW_DIR) if f.lower().endswith(".png")]
screenshots.sort()

results = {}

for filename in screenshots:
    filepath = os.path.join(RAW_DIR, filename)
    print(f"\\nAnalyzing {filename}...")
    
    # 1. Color/Size Analysis using PIL
    try:
        with Image.open(filepath) as img:
            width, height = img.size
            # Convert to RGB to get average color
            rgb_img = img.convert('RGB')
            # Resize to 1x1 to get average color
            avg_color = rgb_img.resize((1, 1)).getpixel((0, 0))
            
            # Let's get corner or specific section colors if helpful
            top_left_color = rgb_img.getpixel((10, 10))
            bottom_right_color = rgb_img.getpixel((width - 10, height - 10))
    except Exception as e:
        print(f"PIL error: {e}")
        width, height = 0, 0
        avg_color = (0, 0, 0)
        top_left_color = (0, 0, 0)
        bottom_right_color = (0, 0, 0)
        
    # 2. OCR using Swift and Apple Vision
    ocr_lines = []
    try:
        proc = subprocess.run(
            ["swift", swift_script_path, filepath],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=30
        )
        if proc.returncode == 0:
            ocr_lines = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
        else:
            print(f"Swift error: {proc.stderr}")
    except Exception as e:
        print(f"Subprocess error: {e}")
        
    results[filename] = {
        "width": width,
        "height": height,
        "avg_color": avg_color,
        "top_left_color": top_left_color,
        "bottom_right_color": bottom_right_color,
        "ocr_lines": ocr_lines
    }
    
    print(f"Dimensions: {width}x{height}")
    print(f"Average Color (RGB): {avg_color}")
    print(f"OCR recognized {len(ocr_lines)} lines:")
    for line in ocr_lines[:15]:
        print(f"  - {line}")
    if len(ocr_lines) > 15:
        print(f"  - ... and {len(ocr_lines) - 15} more lines")

# Save analysis to JSON for future reference
json_path = os.path.join(SCRATCH_DIR, "analysis_results.json")
with open(json_path, "w") as f:
    json.dump(results, f, indent=4)
print(f"\\nAnalysis results saved to: {json_path}")
