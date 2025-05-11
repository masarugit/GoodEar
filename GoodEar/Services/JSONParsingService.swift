// Services/JSONParsingService.swift

// Foundation をインポートすると、URL や Data、JSONDecoder、TimeInterval など
// Swift の基本機能が使えるようになります。
import Foundation

/// JSONParsingService は、Whisper が出力する JSON
/// （TranscriptSegment の配列）を読み込んだり、
/// それを「話し声の切れ目」でグループ化して任意の長さに分割する処理を提供する構造体です。
struct JSONParsingService {
    //====================================================================
    // 既存の JSON ファイル読み込みメソッド
    //====================================================================
    /// JSON ファイルを読み込んで、TranscriptSegment の配列として返します。
    /// - Parameter url: 読み込む JSON ファイルの URL
    /// - Returns: JSON をデコードした TranscriptSegment の配列。失敗時は空配列。
    static func loadRawSegments(from url: URL) -> [TranscriptSegment] {
        do {
            // ファイルの中身をバイト列として読み込む
            let data = try Data(contentsOf: url)
            // JSONDecoder を使って [TranscriptSegment] に変換
            return try JSONDecoder().decode([TranscriptSegment].self, from: data)
        } catch {
            // エラーが発生したらコンソールにログを出力し、空配列を返す
            print("🔴 JSONParsingService.parse error:", error)
            return []
        }
    }

    //====================================================================
    // セグメントを話し声の区切れ目でまとめ、累積時間で新しいセクションを作るメソッド
    //====================================================================
    /// Whisper JSON から得た生のセグメントを、話の区切れ目で区切りつつ、
    /// 累積時間が `targetSize` (デフォルト25秒) を超えたら
    /// 新しいセクションを開始して結果を返します。
    ///
    /// - Parameters:
    ///   - segments: Whisper JSON をデコードして得られた、元のセグメント配列
    ///   - targetSize: 1 セクションあたりの目安となる最大秒数（デフォルト 25 秒）
    /// - Returns: 分割後のセクション配列
    static func chunkSegments(
        _ segments: [TranscriptSegment],
        targetSize: TimeInterval = 25
    ) -> [TranscriptSegment] {
        // 最終的に返すセクションを格納する配列
        var result: [TranscriptSegment] = []
        // 現在まとめているセグメント群
        var currentGroup: [TranscriptSegment] = []
        // currentGroup の開始時刻を保持する変数
        var groupStart: TimeInterval = 0

        // (1) すべての元セグメントを順番に処理
        for seg in segments {
            if currentGroup.isEmpty {
                // currentGroup が空の場合：新しいセクションの開始
                groupStart = seg.start
                currentGroup.append(seg)
            } else {
                // 現在のセクション開始から、次のセグメントの終了までの累積時間を計算
                let potentialEnd = seg.end
                let accumulated = potentialEnd - groupStart

                if accumulated <= targetSize {
                    // (2a) 累積が targetSize 以下なら同じセクションに追加
                    currentGroup.append(seg)
                } else {
                    // (2b) targetSize を超えたら、currentGroup をひとつのセクションとして確定
                    let text = currentGroup.map(\.text).joined(separator: " ")
                    let start = groupStart
                    let end   = currentGroup.last!.end
                    result.append(
                        TranscriptSegment(start: start,
                                          end: end,
                                          text: text)
                    )
                    // 新しいセクションを開始
                    groupStart = seg.start
                    currentGroup = [seg]
                }
            }
        }

        // (3) ループ後にまだ残っているグループを最後のセクションとして追加
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

        // デバッグ用ログ：最終的に何セクションに分割されたかを出力
        print("🔹 chunked into \(result.count) sections by speech breaks")
        return result
    }
}
