//
//  CSVExportDocument.swift
//  SubsqManager
//
//  Created by 森崎大夢 on 2026/05/20.
//

import SwiftUI
import UniformTypeIdentifiers

/// CSVエクスポート用のドキュメント構造体。
/// iOSのShareLinkでファイルを共有するためにTransferableプロトコルに準拠。
struct CSVExportDocument: Transferable {
    let csvString: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            // UTF8エンコーディングでDataに変換
            guard let data = document.csvString.data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            
            // Excel等での文字化けを防ぐため、UTF-8 BOMを付与する
            let bom = Data([0xEF, 0xBB, 0xBF])
            return bom + data
        }
    }
    
    enum ExportError: Error {
        case encodingFailed
    }
}
