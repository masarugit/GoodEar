// Foundation は Swift の基本ライブラリで、String や URL、UUID などの基本型を提供します。
import Foundation

// FilePair 構造体は「音声ファイル」と「対応する JSON ファイル」のペアを表現します。
// Identifiable プロトコルに準拠することで、SwiftUI の List などで自動的に識別できるようになります。
struct FilePair: Identifiable {
    // Identifiable プロトコルで必要な一意の識別子。
    // UUID() を使うと、重複しないランダムな ID が生成されます。
    let id = UUID()
    
    // audio と text のペアを結びつけるための「ファイル名の共通部分」。
    // 例: "lesson1.mp3" と "lesson1.json" の場合、baseName は "lesson1"。
    let baseName: String
    
    // 音声ファイルの場所を示す URL。
    // ファイルシステムやファイルプロバイダ上のパスを表現できます。
    let audioURL: URL
    
    // トランスクリプト（Whisper JSON）が保存されているファイルの URL。
    let textURL: URL
}
