// LessonListView.swift

// SwiftUI フレームワークを読み込むと、View や NavigationStack、List などの UI 構成要素が使えます。
import SwiftUI
// フォルダ選択で使う Uniform Type Identifiers（UTType）を読み込むためのライブラリです。
import UniformTypeIdentifiers

// LessonListView はアプリ起動後に最初に表示される画面で、
// レッスン一覧の表示とフォルダのインポートを担当する View です。
struct LessonListView: View {
    // LessonListViewModel をインスタンス化し、View のライフサイクルに合わせて管理します。
    @StateObject private var viewModel = LessonListViewModel()

    // init は View が最初に生成されるときに一度だけ呼ばれます。
    init() {
        // デバッグ用に、初期化されたことをコンソールに出力します。
        NSLog("🔍 LessonListView.init")
    }

    // body プロパティ内で、この View の見た目を宣言的に定義します。
    var body: some View {
        // NavigationStack は画面遷移を管理するコンテナです。
        NavigationStack {
            // List はスクロール可能な縦方向のリストを作ります。
            List {
                // filePairs が空の場合の表示
                if viewModel.filePairs.isEmpty {
                    Text("No lessons found")
                        .foregroundColor(.red)     // テキストを赤く表示
                        .onAppear {
                            // View が表示されたときにログを出します。
                            NSLog("⚠️ LessonListView: filePairs is EMPTY")
                        }
                }
                // filePairs の配列を順に処理し、各要素を List の行として表示
                ForEach(viewModel.filePairs) { pair in
                    // NavigationLink でタップ時に SectionListView へ遷移
                    NavigationLink {
                        SectionListView(filePair: pair)
                    } label: {
                        Text(pair.baseName)
                            .onAppear {
                                // 各行が描画されるたびにログを出します。
                                NSLog("➡️ LessonListView: rendering row \(pair.baseName)")
                            }
                    }
                }
            }
            // ナビゲーションバーのタイトルを設定
            .navigationTitle("Lessons")
            // ナビゲーションバー右側にツールバーアイテムを追加
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // フォルダアイコンのボタンを配置し、タップで isImporting を true に
                    Button {
                        viewModel.isImporting = true
                    } label: {
                        Image(systemName: "folder")
                    }
                    .onAppear {
                        // ボタンが表示されたときのログ
                        NSLog("👀 LessonListView: import button appeared")
                    }
                }
            }
            // fileImporter でフォルダ選択ダイアログを表示
            .fileImporter(
                isPresented: $viewModel.isImporting,          // on/off を ViewModel で管理
                allowedContentTypes: [.folder],                // フォルダのみ許可
                allowsMultipleSelection: false                 // 複数選択不可
            ) { result in
                // ユーザー操作の結果をハンドル
                switch result {
                case .success(let urls):
                    // 選択された URL があれば
                    if let url = urls.first {
                        NSLog("📂 LessonListView: imported folder at \(url.path)")
                        viewModel.importFolder(url: url)       // フォルダをコピー＆スキャン
                    }
                case .failure(let err):
                    // 選択に失敗した場合のログ
                    NSLog("🔴 LessonListView: folder import error: \(err)")
                }
            }
        }
        // View が表示されるたびに呼ばれる onAppear でデバッグログを出力
        .onAppear {
            NSLog("👀 LessonListView.onAppear – filePairs.count = \(viewModel.filePairs.count)")
        }
    }
}
