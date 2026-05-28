import Cocoa

let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 72),
    .foregroundColor: NSColor.black,
    .paragraphStyle: {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()
]

func createScreenshot(
    inputPath: String,
    outputPath: String,
    text: String,
    backgroundColor: NSColor
) {
    let targetWidth: CGFloat = 1290
    let targetHeight: CGFloat = 2796
    
    guard let inputImage = NSImage(contentsOfFile: inputPath) else {
        print("Failed to load \(inputPath)")
        return
    }
    
    let resultImage = NSImage(size: NSSize(width: targetWidth, height: targetHeight))
    resultImage.lockFocus()
    
    // Draw background
    backgroundColor.setFill()
    NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight).fill()
    
    // Draw text (MacOS coordinates are bottom-left origin)
    // We want text at the top. So Y = targetHeight - 300
    let textRect = NSRect(x: 50, y: targetHeight - 400, width: targetWidth - 100, height: 200)
    
    let attributedString = NSAttributedString(string: text, attributes: textAttributes)
    attributedString.draw(in: textRect)
    
    // Draw screenshot
    // We want it to be centered horizontally, and anchored to the bottom.
    // The screenshot should take up most of the space below the text.
    let targetImageWidth: CGFloat = 1100
    let ratio = targetImageWidth / inputImage.size.width
    let targetImageHeight = inputImage.size.height * ratio
    
    let imageRect = NSRect(
        x: (targetWidth - targetImageWidth) / 2,
        y: targetHeight - 500 - targetImageHeight, // 500px from top
        width: targetImageWidth,
        height: targetImageHeight
    )
    
    // Add shadow
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -20)
    shadow.shadowBlurRadius = 30
    shadow.set()
    
    // Draw rounded rect for image clipping (simulate device)
    let clipPath = NSBezierPath(roundedRect: imageRect, xRadius: 60, yRadius: 60)
    clipPath.fill() // draw shadow
    clipPath.addClip()
    
    inputImage.draw(in: imageRect, from: NSRect(origin: .zero, size: inputImage.size), operation: .sourceOver, fraction: 1.0)
    
    NSGraphicsContext.current?.restoreGraphicsState()
    
    resultImage.unlockFocus()
    
    // Save to file
    guard let tiffData = resultImage.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG data")
        return
    }
    
    try? pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Saved \(outputPath)")
}

let args = CommandLine.arguments
if args.count < 3 {
    print("Usage: swift script.swift <inputDir> <outputDir>")
    exit(1)
}

let inputDir = args[1]
let outputDir = args[2]

// Define the 4 images and their texts
// We will try to map the uploaded filenames to the 4 scenarios based on file sizes or timestamps.
// The 4 recent files are:
// 1779690045698 (Registration / Quick Add)
// 1779689986117 (Dashboard)
// 1779689959678 (Review swipe)
// 1779689893984 (Calendar)
// Note: I will map them directly.

let mapping = [
    ("media__1779689893984.png", "リストだけじゃない。カレンダーで見える化", NSColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 1.0)),
    ("media__1779689986117.png", "今月、実際に支払う額を正確に把握。", NSColor(red: 1.0, green: 0.96, blue: 0.95, alpha: 1.0)),
    ("media__1779689959678.png", "直感的なスワイプで、無駄な出費を断捨離", NSColor(red: 0.98, green: 0.95, blue: 0.98, alpha: 1.0)),
    ("media__1779690045698.png", "レシートや画像から自動入力＆爆速登録", NSColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1.0))
]

try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for (idx, item) in mapping.enumerated() {
    let inPath = inputDir + "/" + item.0
    let outPath = outputDir + "/Screenshot_\(idx + 1).png"
    createScreenshot(inputPath: inPath, outputPath: outPath, text: item.1, backgroundColor: item.2)
}
