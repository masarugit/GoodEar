// Foundation は Swift の基本ライブラリです。
// String や URL、TimeInterval などの基礎的な型を提供します。
import Foundation

// SwiftData は iOS 17+ 向けの永続化フレームワークです。
// @Model 属性を使ってデータベースに保存できるクラスを定義します。
import SwiftData

// @Model を付けると、このクラスが SwiftData のエンティティ（テーブル）になります。
// SwiftData はこの定義をもとに自動で保存・読み込みのコードを作ります。
@Model
// final は「このクラスを継承できない」ことを示します。
// 継承が不要なモデルクラスでは final を付けることでパフォーマンスが向上します。
final class Section {
    // start はセクションの開始時刻（秒）を表すプロパティです。
    // TimeInterval は秒を表す Double 型の別名です。
    var start: TimeInterval
    
    // end はセクションの終了時刻（秒）を表すプロパティです。
    var end: TimeInterval
    
    // text はそのセクションで表示する文字起こしテキストを保持します。
    // String は Swift の標準的な文字列型です。
    var text: String

    // イニシャライザ（コンストラクタ）は、このクラスのインスタンスを作るときに呼ばれます。
    // 引数で受け取った start/end/text をプロパティにセットしています。
    init(start: TimeInterval, end: TimeInterval, text: String) {
        // self.start は「このインスタンスの start プロパティ」を指します。
        self.start = start
        // self.end は「このインスタンスの end プロパティ」を指します。
        self.end = end
        // self.text は「このインスタンスの text プロパティ」を指します。
        self.text = text
    }
}
