// AttributedTextView.swift

import SwiftUI
import UIKit

/// UITextView をラップし、NSAttributedString を表示、
/// 単語単位で選択・コピー・辞書検索を可能にするビュー
struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // スクロール位置を覚えておく
        let savedOffset = uiView.contentOffset

        // attributedText を更新
        uiView.attributedText = attributedText

        // 直前のスクロール位置に戻す
        uiView.setContentOffset(savedOffset, animated: false)
    }
}

