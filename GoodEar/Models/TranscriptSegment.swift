// TranscriptSegment.swift

import Foundation

/// 再生セクション／字幕ブロックの開始時刻・終了時刻・テキストを表すデータモデル
/// SRT でも Whisper JSON でも、この構造体を通じて共通に扱います。
struct TranscriptSegment: Codable, Identifiable, Equatable {
    /// セクションの開始時刻（秒）
    let start: TimeInterval
    /// セクションの終了時刻（秒）
    let end: TimeInterval
    /// セクション内のテキスト
    let text: String

    /// Identifiable プロトコルで必要な一意の識別子。
    /// start をそのまま ID として使います。
    var id: TimeInterval { start }
}
