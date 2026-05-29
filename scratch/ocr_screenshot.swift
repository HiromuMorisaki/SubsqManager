import Foundation
import Vision
import Cocoa

func recognizeText(in imagePath: String) {
    guard let image = NSImage(contentsOfFile: imagePath),
          let tiffData = image.tiffRepresentation,
          let cgImageSource = CGImageSourceCreateWithData(tiffData as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else {
        print("Failed to load image at \(imagePath)")
        return
    }
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let texts = observations.compactMap { $0.topCandidates(1).first?.string }
        print("--- OCR TEXT START ---")
        for text in texts {
            print(text)
        }
        print("--- OCR TEXT END ---")
    }
    request.recognitionLanguages = ["ja-JP", "en-US"]
    
    do {
        try requestHandler.perform([request])
    } catch {
        print("Failed to perform OCR: \(error)")
    }
}

let args = CommandLine.arguments
if args.count > 1 {
    recognizeText(in: args[1])
} else {
    print("Usage: swift ocr_screenshot.swift <image_path>")
}
