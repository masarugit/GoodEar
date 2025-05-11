// PlaybackModalView.swift

import SwiftUI

/// モーダル内でチャンク単位の再生操作と、
/// SRT の生セグメント(start/end)を使った正確なハイライト表示＆選択可能テキストを行う View
struct PlaybackModalView: View {
    @StateObject private var vm: PlaybackViewModel
    private let rawSegments: [TranscriptSegment]
    @State private var showText = false
    let onPlay: (TranscriptSegment) -> Void

    init(
        segments: [TranscriptSegment],
        rawSegments: [TranscriptSegment],
        audioURL: URL,
        initial: TranscriptSegment,
        onPlay: @escaping (TranscriptSegment) -> Void
    ) {
        _vm = StateObject(
            wrappedValue: PlaybackViewModel(
                segments: segments,
                audioURL: audioURL,
                initial: initial
            )
        )
        self.rawSegments = rawSegments
        self.onPlay = onPlay
    }

    var body: some View {
        VStack(spacing: 16) {
            // 1. Auto-Play Next Section トグル
            Toggle("Auto-Play Next Section", isOn: $vm.isAutoplayOn)
                .toggleStyle(SwitchToggleStyle())
                .font(.subheadline)
                .padding(.horizontal)

            // 2. セクション移動ボタン & 番号表示
            HStack {
                Spacer()
                Button { prevSection() } label: {
                    Image(systemName: "backward.end.fill").font(.title)
                }
                Spacer()
                Text(String(format: "%03d", vm.currentIndex + 1))
                    .font(.title).fontWeight(.bold)
                Spacer()
                Button { nextSection() } label: {
                    Image(systemName: "forward.end.fill").font(.title)
                }
                Spacer()
            }
            .padding(.top)

            // 3. プログレスバー
            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .padding(.horizontal)

            // 4. 経過時間 / セクション長
            HStack {
                Text(formatTime(vm.currentTime - vm.current.start))
                Spacer()
                Text(formatTime(vm.current.end - vm.current.start))
            }
            .font(.caption)
            .padding(.horizontal)

            // 5. シーク & 再生コントロール
            HStack(spacing: 48) {
                Button { vm.rewind(by: 5) } label: {
                    Image(systemName: "gobackward.5").font(.title)
                }
                Button {
                    if vm.isPlaying { vm.pause() }
                    else { playCurrent() }
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                Button { vm.fastForward(by: 10) } label: {
                    Image(systemName: "goforward.10").font(.title)
                }
            }

            Spacer()

            // 6. Show/Hide Text ボタン
            Button { showText.toggle() } label: {
                Text(showText ? "Hide Text" : "Show Text")
                    .font(.headline)
            }

            // 7. テキスト表示領域：内部スクロールの UITextView を使う
            Group {
                if showText {
                    AttributedTextView(attributedText: highlightedText)
                        .frame(height: 300)                            // 固定高さ
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal)
                } else {
                    Color.clear.frame(height: 300)
                }
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Highlighting Logic

    private var highlightedText: NSAttributedString {
        // チャンクに含まれる SRT セグメントだけ抽出
        let inChunk = rawSegments.filter { seg in
            seg.start < vm.current.end && seg.end > vm.current.start
        }

        // 行間調整
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 2

        let attr = NSMutableAttributedString()
        for seg in inChunk {
            let color: UIColor = (
                vm.currentTime >= seg.start && vm.currentTime < seg.end
            ) ? UIColor(Color.accentColor) : .label

            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: UIFont.preferredFont(forTextStyle: .body),
                .paragraphStyle: para
            ]
            let line = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            attr.append(NSAttributedString(string: line + "\n", attributes: attrs))
        }
        return attr
    }

    // MARK: - Actions

    private func prevSection() {
        vm.pause()
        vm.prev()
        showText = false
        if vm.isAutoplayOn { playCurrent() }
    }

    private func nextSection() {
        vm.pause()
        vm.next()
        showText = false
        if vm.isAutoplayOn { playCurrent() }
    }

    private func playCurrent() {
        vm.play()
        onPlay(vm.current)
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
