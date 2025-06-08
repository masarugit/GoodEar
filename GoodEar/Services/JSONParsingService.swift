// Services/JSONParsingService.swift

import Foundation

/// JSONParsingService は、Whisper が出力する JSON
/// （TranscriptSegment の配列）や SRT などの生セグメントを読み込み、
/// それを「文末ピリオド単位」や「時間閾値単位」でグループ化して
/// セクションを生成するユーティリティです。
struct JSONParsingService {
    //====================================================================
    // 既存の JSON ファイル読み込みメソッド
    //====================================================================
    /// JSON ファイルを読み込んで、TranscriptSegment の配列として返します。
    /// - Parameter url: 読み込む JSON ファイルの URL
    /// - Returns: JSON をデコードした TranscriptSegment の配列。失敗時は空配列。
    static func loadRawSegments(from url: URL) -> [TranscriptSegment] {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([TranscriptSegment].self, from: data)
        } catch {
            print("🔴 JSONParsingService.parse error:", error)
            return []
        }
    }

    //====================================================================
    // 既存の「話し声の区切れ目＋累積時間」でチャンク化するメソッド
    //====================================================================
    /// Whisper JSON から得た生のセグメントを、話の区切れ目で区切りつつ、
    /// 累積時間が targetSize (デフォルト 25 秒) を超えたら
    /// 新しいセクションを開始して結果を返します。
    static func chunkSegments(
        _ segments: [TranscriptSegment],
        targetSize: TimeInterval = 25
    ) -> [TranscriptSegment] {
        var result: [TranscriptSegment] = []
        var currentGroup: [TranscriptSegment] = []
        var groupStart: TimeInterval = 0

        for seg in segments {
            if currentGroup.isEmpty {
                groupStart = seg.start
                currentGroup.append(seg)
            } else {
                let accumulated = seg.end - groupStart
                if accumulated <= targetSize {
                    currentGroup.append(seg)
                } else {
                    let text = currentGroup.map(\.text).joined(separator: " ")
                    let start = groupStart
                    let end   = currentGroup.last!.end
                    result.append(
                        TranscriptSegment(start: start,
                                          end: end,
                                          text: text)
                    )
                    groupStart = seg.start
                    currentGroup = [seg]
                }
            }
        }

        if !currentGroup.isEmpty {
            let text = currentGroup.map(\.text).joined(separator: " ")
            let start = currentGroup.first!.start
            let end   = currentGroup.last!.end
            result.append(
                TranscriptSegment(start: start,
                                  end: end,
                                  text: text)
            )
        }

        print("🔹 chunked into \(result.count) sections by speech breaks")
        return result
    }

    //====================================================================
    // 新規：文末ピリオドでまとめたセグメントを作成するメソッド
    //====================================================================
    /// Whisper/SRT の生セグメントを受け取り、
    /// テキストがピリオドで終わるまでつなげて１つの文単位の
    /// TranscriptSegment を作成して返します。
    ///
    /// - Parameter segments: 生の TranscriptSegment 配列
    /// - Returns: 文単位にまとめられた TranscriptSegment 配列
    // 文末ピリオド or クエスチョンでsentence単位で区切る
        static func makeSentenceSegments(from segments: [TranscriptSegment]) -> [TranscriptSegment] {
            var result: [TranscriptSegment] = []
            var currentGroup: [TranscriptSegment] = []

            for seg in segments {
                currentGroup.append(seg)
                let trimmed = seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasSuffix(".") || trimmed.hasSuffix("?") {
                    let text = currentGroup.map(\.text).joined(separator: " ")
                    let start = currentGroup.first!.start
                    let end   = currentGroup.last!.end
                    result.append(
                        TranscriptSegment(start: start, end: end, text: text)
                    )
                    currentGroup.removeAll()
                }
            }
            if !currentGroup.isEmpty {
                let text = currentGroup.map(\.text).joined(separator: " ")
                let start = currentGroup.first!.start
                let end   = currentGroup.last!.end
                result.append(
                    TranscriptSegment(start: start, end: end, text: text)
                )
            }

            print("🔹 split into \(result.count) sentence segments by period/question")
            return result
        }


    //====================================================================
    // 新規：SentenceSegment を時間閾値でチャンク化するメソッド
    //====================================================================
    /// 文単位にまとめられた TranscriptSegment を受け取り、
    /// 累積時間が targetSize（デフォルト 45 秒）を超えたら
    /// 新しいセクションを開始してまとめます。
    ///
    /// - Parameters:
    ///   - sentences: makeSentenceSegments で生成された文単位のセグメント
    ///   - targetSize: 1 セクションあたりの目安となる最大秒数
    /// - Returns: まとまり時間がおおむね targetSize のセクション配列
    // 「文単位でまとめたsentenceSegments」を、累積時間30秒ごとにセクション化
    static func chunkSentences(
        _ sentences: [TranscriptSegment],
        targetSize: TimeInterval = 30
    ) -> [TranscriptSegment] {
        var result: [TranscriptSegment] = []
        var currentGroup: [TranscriptSegment] = []

        for seg in sentences {
            currentGroup.append(seg)
            let groupStart = currentGroup.first!.start
            let groupEnd   = currentGroup.last!.end
            let accumulated = groupEnd - groupStart

            // targetSizeを超えたら（超えた後でFlush）
            if accumulated >= targetSize {
                // 今追加したsegを含めてFlush
                let text = currentGroup.map(\.text).joined(separator: " ")
                result.append(
                    TranscriptSegment(start: groupStart, end: groupEnd, text: text)
                )
                currentGroup.removeAll()
            }
        }

        // 残りを最後のセクションとして追加
        if !currentGroup.isEmpty {
            let groupStart = currentGroup.first!.start
            let groupEnd   = currentGroup.last!.end
            let text = currentGroup.map(\.text).joined(separator: " ")
            result.append(
                TranscriptSegment(start: groupStart, end: groupEnd, text: text)
            )
        }

        print("🔹 chunked sentences into \(result.count) sections (~\(targetSize)s each)")
        return result
    }

    
    // JSONParsingService.swift に新規追加
    static func chunkSentencesToSectionChunks(
        _ sentences: [TranscriptSegment],
        targetSize: TimeInterval = 30
    ) -> [[TranscriptSegment]] {
        var result: [[TranscriptSegment]] = []
        var currentGroup: [TranscriptSegment] = []
        var groupStart: TimeInterval = 0

        for seg in sentences {
            if currentGroup.isEmpty {
                groupStart = seg.start
                currentGroup.append(seg)
            } else {
                let accumulated = seg.end - groupStart
                if accumulated <= targetSize {
                    currentGroup.append(seg)
                } else {
                    result.append(currentGroup)
                    groupStart = seg.start
                    currentGroup = [seg]
                }
            }
        }
        if !currentGroup.isEmpty {
            result.append(currentGroup)
        }
        return result
    }

}
