import SwiftUI
import UIKit

/// UITextView をラップし、選択と辞書引きを有効にしたビュー
/// テキスト色を指定できるようになりました。
struct SelectableTextView: UIViewRepresentable {
    let text: String
    let textColor: UIColor    // ← 追加

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.dataDetectorTypes = []
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textColor = textColor  // ← 追加
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.textColor = textColor  // ← 追加
    }
}
