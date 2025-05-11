import Foundation

/// SRT 形式のファイルを読み込み、各ブロックを TranscriptSegment に変換するサービス
struct SRTParsingService {
    /// SRT ファイルの URL を受け取り、パース結果を返す
    static func loadSegments(from url: URL) -> [TranscriptSegment] {
        guard let srt = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        var segments: [TranscriptSegment] = []
        // ブロックごとに空行で分割
        let blocks = srt.components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.split(whereSeparator: \.isNewline).map(String.init)
            guard lines.count >= 2 else { continue }
            // 2行目が "00:00:12,380 --> 00:00:16,020" のようなタイムコード
            let times = lines[1].components(separatedBy: " --> ")
            guard times.count == 2,
                  let start = parseTime(times[0]),
                  let end   = parseTime(times[1]) else { continue }
            // 3行目以降を結合して字幕テキストに
            let text = lines.dropFirst(2).joined(separator: " ")
            segments.append(TranscriptSegment(start: start, end: end, text: text))
        }
        return segments
    }

    /// "HH:MM:SS,mmm" を秒数の Double に変換するヘルパー
    private static func parseTime(_ s: String) -> TimeInterval? {
        // "00:00:12,380" → ["00","00","12,380"]
        let parts = s.split(separator: ":").map(String.init)
        guard parts.count == 3 else { return nil }
        let h = Double(parts[0]) ?? 0
        let m = Double(parts[1]) ?? 0
        // "12,380" を ["12","380"] → 秒＋ミリ秒
        let secParts = parts[2].split(separator: ",").map(String.init)
        guard secParts.count == 2,
              let sec = Double(secParts[0]),
              let ms  = Double(secParts[1]) else { return nil }
        return h * 3600 + m * 60 + sec + ms/1000
    }
}
