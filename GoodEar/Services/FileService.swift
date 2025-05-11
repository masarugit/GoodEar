// Services/FileService.swift

import Foundation

/// FileService は、ユーザーが選択したフォルダを
/// アプリ内の Documents/ImportedLessons にコピーし、
/// 音声ファイル(mp3/wav/m4a) と同名の .srt ファイルをペアとして検出します。
struct FileService {
    /// Documents 内に作成するルートフォルダ名
    private static let importedFolderName = "ImportedLessons"

    //================================================================
    // フォルダのコピー
    //================================================================
    /// ドキュメントピッカーで選択したフォルダ (srcURL) を
    /// サンドボックス内の Documents/ImportedLessons/<フォルダ名> に丸ごとコピーします。
    /// - Parameter srcURL: ユーザーが選択した元フォルダの URL
    /// - Returns: コピー先フォルダの URL
    /// - Throws: コピーやディレクトリ操作に失敗した場合のエラー
    static func copyFolderToAppStorage(from srcURL: URL) throws -> URL {
        let fm = FileManager.default
        print("▶️ FileService: copyFolderToAppStorage from \(srcURL.path)")

        // セキュリティスコープ開始 (ファイルプロバイダ経由のアクセス)
        var didStartScope = false
        if srcURL.startAccessingSecurityScopedResource() {
            didStartScope = true
            print("🚀 Security scope started for \(srcURL.path)")
        } else {
            print("❌ Failed to start security scope for \(srcURL.path)")
        }
        defer {
            if didStartScope {
                srcURL.stopAccessingSecurityScopedResource()
                print("🛑 Security scope stopped for \(srcURL.path)")
            }
        }

        // Documents ディレクトリの URL を取得
        let docs = try fm.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        print("📂 Documents directory: \(docs.path)")

        // ImportedLessons フォルダを準備（既存なら削除して再作成）
        let destRoot = docs.appendingPathComponent(importedFolderName, isDirectory: true)
        print("📂 Dest root: \(destRoot.path)")
        if fm.fileExists(atPath: destRoot.path) {
            print("🗑 Removing existing ImportedLessons folder")
            try fm.removeItem(at: destRoot)
        }
        try fm.createDirectory(at: destRoot, withIntermediateDirectories: true)
        print("✅ Created ImportedLessons folder")

        // 実際にフォルダをコピー
        let destFolder = destRoot.appendingPathComponent(srcURL.lastPathComponent, isDirectory: true)
        print("📂 Copying \(srcURL.lastPathComponent) to \(destFolder.path)")
        try fm.copyItem(at: srcURL, to: destFolder)
        print("✅ Copy successful to \(destFolder.path)")

        return destFolder
    }

    //================================================================
    // フォルダのスキャン
    //================================================================
    /// アプリ内にコピー済みのフォルダをスキャンし、
    /// mp3/wav/m4a ファイルと同名の .srt ファイルを検出して [FilePair] を返します。
    /// - Parameter url: スキャン対象フォルダの URL
    /// - Returns: 見つかった FilePair の配列
    static func scanFolder(at url: URL) -> [FilePair] {
        var results: [FilePair] = []
        let fm = FileManager.default

        print("▶️ FileService: scanFolder at \(url.path)")

        // フォルダ内のアイテム一覧を取得
        let items: [URL]
        do {
            items = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            )
            print("📂 Found \(items.count) items in folder")
        } catch {
            print("🔴 FileService: contentsOfDirectory error:", error)
            return []
        }

        // 対象とする音声ファイルの拡張子リスト
        let audioExts = ["mp3", "wav", "m4a"]
        for file in items where audioExts.contains(file.pathExtension.lowercased()) {
            let base = file.deletingPathExtension().lastPathComponent
            // 同名の .srt ファイルが存在するかチェック
            let srtURL = url.appendingPathComponent("\(base).srt")
            if fm.fileExists(atPath: srtURL.path) {
                print("✅ Pair found: \(base)")
                results.append(
                    FilePair(
                        baseName: base,
                        audioURL: file,
                        textURL: srtURL
                    )
                )
            }
        }

        print("📄 scanFolder: returning \(results.count) FilePair(s)")
        return results
    }
}
