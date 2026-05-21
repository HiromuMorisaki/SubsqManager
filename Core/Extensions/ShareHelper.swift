//
//  ShareHelper.swift
//  SubsqManager
//
//  Created by Hiromu on 2026/05/21.
//

import SwiftUI

#if os(iOS)
import UIKit

extension View {
    /// 与えられた画像をシステム共有シート（UIActivityViewController）を使用して共有します。
    /// iPadでのクラッシュを防ぐため、最前面の画面中央にポップオーバーを表示する安全設計です。
    @MainActor
    func shareImage(_ image: UIImage, completion: (() -> Void)? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        // 最前面のビューコントローラを探索
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        // iPad対応の設定（popoverPresentationController が存在する場合）
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            // 画面中央にポップオーバーを表示
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true, completion: completion)
    }
}
#else
extension View {
    /// 非iOS環境（macOS等）向けのフォールバック実装
    func shareImage(_ image: Any, completion: (() -> Void)? = nil) {
        // 必要に応じて将来的にmacOS固有の共有ロジック（NSSharingServicePickerなど）を組み込めます。
        print("Sharing is only supported on iOS.")
        completion?()
    }
}
#endif
