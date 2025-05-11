// Services/LessonListViewModel.swift

// Foundation は Swift の基本ライブラリで、URL や UserDefaults、FileManager などを提供します。
import Foundation
// UniformTypeIdentifiers はファイルの種類（UTType）を扱うライブラリです。
// ここではフォルダ選択時に利用することを想定しています。
import UniformTypeIdentifiers

// @MainActor を付けると、このクラスのメソッドやプロパティは必ずメインスレッドで実行されます。
// UI 更新と密接に連動する ViewModel では、メインスレッドで動かす必要があります。
@MainActor
// ObservableObject を継承すると、このクラスの @Published プロパティが変化したときに
// SwiftUI の View が自動で再描画されるようになります。
class LessonListViewModel: ObservableObject {
    // @Published を付けたプロパティは変更を監視可能にし、View に通知されます。
    // filePairs は画面に表示する FilePair の配列です。最初は空配列で初期化。
    @Published var filePairs: [FilePair] = []
    // isImporting はフォルダ選択ダイアログを表示中かどうかを示すフラグです。
    @Published var isImporting = false

    // UserDefaults に保存するキーを定数として用意。
    // アプリを再起動したときに、前回インポートしたフォルダ名を読み出すために使います。
    private let savedFolderKey = "SavedImportedFolderName"

    // イニシャライザ。インスタンス生成時に一度だけ実行されます。
    init() {
        // ① まず UserDefaults から以前保存したフォルダ名を取り出してみる
        if let folderName = UserDefaults.standard.string(forKey: savedFolderKey) {
            // folderName が存在すれば、Documents/ImportedLessons/<folderName> を再スキャン
            let fm = FileManager.default
            // ドキュメントディレクトリを取得（create: false は既存のみ取得）
            if let docs = try? fm.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ) {
                // ImportedLessons フォルダのパス
                let root = docs.appendingPathComponent("ImportedLessons", isDirectory: true)
                // 保存されていたサブフォルダ名を足して、実際の保存先 URL を作成
                let savedFolder = root.appendingPathComponent(folderName, isDirectory: true)
                // ファイルペアをスキャンして filePairs にセット
                self.filePairs = FileService.scanFolder(at: savedFolder)
            }
        }
    }

    /// ユーザーが選択したフォルダの URL を受け取り、
    /// FileService を介してコピー → スキャン → UserDefaults への保存を行います。
    /// - Parameter url: ドキュメントピッカーで選択されたフォルダの URL
    func importFolder(url: URL) {
        do {
            // フォルダをサンドボックス内にコピー
            let local = try FileService.copyFolderToAppStorage(from: url)
            // コピー先のフォルダをスキャンして filePairs を更新
            filePairs = FileService.scanFolder(at: local)
            // フォルダ名（lastPathComponent）を UserDefaults に保存
            // 次回起動時に同じフォルダを自動で読み込めるようになります
            UserDefaults.standard.set(local.lastPathComponent, forKey: savedFolderKey)
        } catch {
            // エラー発生時はコンソールにメッセージを出力
            print("🔴 importFolder error:", error)
        }
    }
}
