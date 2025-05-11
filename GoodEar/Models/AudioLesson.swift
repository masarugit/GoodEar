// Foundation は Swift の基本ライブラリで、String や URL といった型を提供します。
import Foundation
// SwiftData は iOS 17+ 向けのデータ永続化フレームワークで、@Model などを使って簡単にデータを保存できます。
import SwiftData

// @Model 属性を付けると、このクラスがデータベースに保存できるエンティティ（モデル）になります。
// SwiftData がこのクラス用のテーブルを自動生成してくれます。
@Model
// final キーワードは「このクラスを継承してはいけません」という意味です。
// 継承を禁止することで最適化が効きやすくなります。
final class AudioLesson {
    // @Attribute(.unique) を付けると、このプロパティがユニーク制約（重複禁止）付きで保存されます。
    // var title: String は「タイトル」という文字列を保持する変数です。
    @Attribute(.unique) var title: String

    // var audioURL: URL は、音声ファイルの場所を表す URL 型の変数です。
    // URL はファイルのパスや Web アドレスを扱うための型です。
    var audioURL: URL

    // @Relationship は別モデルとの関係性を表します。
    // ここでは「一つの AudioLesson に複数の Section が関連付く」一対多の関係です。
    // 初期値として空の配列 [] を代入しています。
    @Relationship var sections: [Section] = []

    // イニシャライザ（コンストラクタ）は、クラスのインスタンスを生成するときに呼ばれます。
    // title と audioURL を引数で受け取り、プロパティにセットしています。
    // self.title の self は「このインスタンス自身」を指します。
    init(title: String, audioURL: URL) {
        self.title = title
        self.audioURL = audioURL
    }
}
