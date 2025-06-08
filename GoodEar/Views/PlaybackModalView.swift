// Views/PlaybackModalView.swift

import SwiftUI
import UIKit  // AttributedTextView のために必要

/// モーダル内でチャンク単位の再生操作と、
/// 文末(. or ?)区切りでまとめた全文リストから
/// 動的にセクションごとの文をフィルタし、
/// sentence 単位で前後移動＆ハイライト表示する View
struct PlaybackModalView: View {
    @StateObject private var vm: PlaybackViewModel
    let allSentenceSegments: [TranscriptSegment]  // 全文単位セグメント
    @State private var showText = false
    let onPlay: (TranscriptSegment) -> Void

    init(
        segments: [TranscriptSegment],
        allSentenceSegments: [TranscriptSegment],
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
        self.allSentenceSegments = allSentenceSegments
        self.onPlay = onPlay
    }

    var body: some View {
        VStack(spacing: 16) {
            // 1. Auto-Play Next Section トグル
            Toggle("Auto-Play Next Section", isOn: $vm.isAutoplayOn)
                .toggleStyle(SwitchToggleStyle())
                .font(.subheadline)
                .padding(.horizontal)

            // 2. セクション移動ボタン & 番号
            HStack {
                Spacer()
                Button {
                    vm.pause()
                    vm.prev()
                    showText = false
                    if vm.isAutoplayOn {
                        vm.play()
                        onPlay(vm.current)
                    }
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title)
                }
                Spacer()
                Text(String(format: "%03d", vm.currentIndex + 1))
                    .font(.title).fontWeight(.bold)
                Spacer()
                Button {
                    vm.pause()
                    vm.next()
                    showText = false
                    if vm.isAutoplayOn {
                        vm.play()
                        onPlay(vm.current)
                    }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.title)
                }
                Spacer()
            }
            .padding(.top)

            // 3. プログレスバー
            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .padding(.horizontal)

            // 4. 経過時間／セクション長表示
            HStack {
                Text(formatTime(vm.currentTime - vm.current.start))
                Spacer()
                Text(formatTime(vm.current.end - vm.current.start))
            }
            .font(.caption)
            .padding(.horizontal)

            // 5. シーク＆文単位移動コントロール
            HStack(spacing: 32) {
                // — 文単位で「前へ」（セクションまたぎ対応）
                Button {
                    let wasPlaying = vm.isPlaying
                    vm.pause()

                    // このセクションの文を動的に抽出
                    let sectionSentences = allSentenceSegments.filter {
                        $0.end > vm.current.start && $0.start < vm.current.end
                    }
                    // 現在Timeより前の最後の文を探す
                    if let idx = sectionSentences.lastIndex(where: { $0.start < vm.currentTime }) {
                        // セクション内の前の文へ
                        let target = sectionSentences[idx].start
                        vm.seek(to: target)
                    } else {
                        // セクションの先頭よりも前 → 前セクションの最後の文へ
                        if vm.currentIndex > 0 {
                            vm.prev()
                            let prevSection = vm.current
                            let prevSentences = allSentenceSegments.filter {
                                $0.end > prevSection.start && $0.start < prevSection.end
                            }
                            if let last = prevSentences.last {
                                vm.seek(to: last.start)
                            }
                        }
                    }

                    if wasPlaying { vm.play() }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title)
                }

                // — 5秒戻る
                Button {
                    vm.rewind(by: 5)
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title)
                }

                // — 再生／一時停止
                Button {
                    if vm.isPlaying {
                        vm.pause()
                    } else {
                        vm.play()
                        onPlay(vm.current)
                    }
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }

                // — 10秒進む
                Button {
                    vm.fastForward(by: 10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title)
                }

                // — 文単位で「次へ」（セクションまたぎ対応）
                Button {
                    let wasPlaying = vm.isPlaying
                    vm.pause()

                    let sectionSentences = allSentenceSegments.filter {
                        $0.end > vm.current.start && $0.start < vm.current.end
                    }
                    // 現在Timeより後の最初の文を探す
                    if let idx = sectionSentences.firstIndex(where: { $0.start > vm.currentTime }) {
                        let target = sectionSentences[idx].start
                        vm.seek(to: target)
                    } else {
                        // セクションの末尾より後 → 次セクションの最初の文へ
                        if vm.currentIndex + 1 < vm.segments.count {
                            vm.next()
                            let nextSection = vm.current
                            let nextSentences = allSentenceSegments.filter {
                                $0.end > nextSection.start && $0.start < nextSection.end
                            }
                            if let first = nextSentences.first {
                                vm.seek(to: first.start)
                            }
                        }
                    }

                    if wasPlaying { vm.play() }
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title)
                }
            }
            .padding(.horizontal)

            Spacer()

            // 6. Show/Hide Text
            Button {
                showText.toggle()
            } label: {
                Text(showText ? "Hide Text" : "Show Text")
                    .font(.headline)
            }

            // 7. テキスト表示領域
            if showText {
                let sectionSentences = allSentenceSegments.filter {
                    $0.end > vm.current.start && $0.start < vm.current.end
                }
                AttributedTextView(attributedText: makeHighlightedText(from: sectionSentences))
                    //.id(vm.currentTime)
                    .frame(height: 300)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                Color.clear.frame(height: 300)
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func makeHighlightedText(from sentences: [TranscriptSegment]) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        for seg in sentences {
            let isActive = (vm.currentTime >= seg.start && vm.currentTime < seg.end)
            let color: UIColor = isActive ? UIColor(Color.accentColor) : .label
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: UIFont.preferredFont(forTextStyle: .body)
            ]
            let line = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            attr.append(NSAttributedString(string: line + "\n", attributes: attrs))
        }
        if attr.length == 0 {
            return NSAttributedString(
                string: vm.current.text,
                attributes: [
                    .foregroundColor: UIColor.label,
                    .font: UIFont.preferredFont(forTextStyle: .body)
                ]
            )
        }
        return attr
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
