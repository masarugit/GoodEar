import Foundation
import Combine
import UniformTypeIdentifiers
import SwiftUI

@MainActor
class SectionListViewModel: ObservableObject {

    /// 30~40秒くらいの「セクション」リスト
    @Published var segments: [TranscriptSegment] = []
    /// 生セグメントを文末(. or ?)でまとめた sentenceSegments 全体
    @Published var allSentenceSegments: [TranscriptSegment] = []
    @Published var selectedSegment: TranscriptSegment?

    /// 再生済みセクションID のセット
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

    /// フォルダ内の JSON/SRT を読み込んで
    /// ① 文末(. or ?)で sentenceSegments にまとめ
    /// ② それを 40秒目安で chunk して segments(セクション) に格納
    func loadSegments() {
        // 生セグメントを読み込む
        let raw: [TranscriptSegment] = filePair.textURL.pathExtension.lowercased() == "srt"
            ? SRTParsingService.loadSegments(from: filePair.textURL)
            : JSONParsingService.loadRawSegments(from: filePair.textURL)

        // ① 文末(. or ?)で区切って sentenceSegments を作成
        let sentences = JSONParsingService.makeSentenceSegments(from: raw)
        self.allSentenceSegments = sentences

        // ② 30秒目安でチャンク化 → セクション
        let sectionChunks = JSONParsingService.chunkSentences(sentences, targetSize: 30)
        self.segments = sectionChunks
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
