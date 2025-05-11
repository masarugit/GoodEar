// Services/SectionListViewModel.swift

import Foundation
import Combine

@MainActor
class SectionListViewModel: ObservableObject {
    @Published var segments: [TranscriptSegment] = []
    @Published var selectedSegment: TranscriptSegment?

    /// 再生済みセクションIDのセット
    @Published private(set) var playedSegmentIDs = Set<TranscriptSegment.ID>()

    let filePair: FilePair
    private let defaults = UserDefaults.standard
    private var saveKey: String { "playedSegments_\(filePair.baseName)" }

    init(filePair: FilePair) {
        self.filePair = filePair
        loadSavedPlayed()
        loadSegments()
    }

    private func loadSavedPlayed() {
        if let arr = defaults.array(forKey: saveKey) as? [Double] {
            playedSegmentIDs = Set(arr.map { TranscriptSegment.ID($0) })
        }
    }

    private func savePlayed() {
        let arr = playedSegmentIDs.map { $0 }
        defaults.set(arr, forKey: saveKey)
    }

    /// JSON / SRT によらず、元データをパースして
    /// 「20–30秒チャンク」にまとめ、segments にセット
    func loadSegments() {
        // まず「生セグメント」を取得
        let raw: [TranscriptSegment]
        if filePair.textURL.pathExtension.lowercased() == "srt" {
            // .srt の場合は SRTParsingService を使う
            raw = SRTParsingService.loadSegments(from: filePair.textURL)
        } else {
            // それ以外（.json）は従来の JSONParsingService
            raw = JSONParsingService.loadRawSegments(from: filePair.textURL)
        }
        // 生セグメントを 20–30秒ごとにまとめてチャンク化
        segments = JSONParsingService.chunkSegments(raw)
    }

    func select(_ segment: TranscriptSegment) {
        selectedSegment = segment
    }

    func markPlayed(_ segment: TranscriptSegment) {
        if playedSegmentIDs.insert(segment.id).inserted {
            savePlayed()
        }
    }

    func isPlayed(_ segment: TranscriptSegment) -> Bool {
        playedSegmentIDs.contains(segment.id)
    }
}
