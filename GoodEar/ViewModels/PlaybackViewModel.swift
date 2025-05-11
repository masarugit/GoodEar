// Services/PlaybackViewModel.swift

// Foundation：Swift の標準ライブラリ。String、Array、Date、TimeInterval などの基本型を提供します。
import Foundation
// AVFoundation：メディア再生や録音などの機能を提供するフレームワーク。
import AVFoundation

// @MainActor：このクラスのすべてのメソッドとプロパティはメインスレッド（UIスレッド）で実行されます。
// UI と同期させたい処理（再生コントロールや状態更新）が含まれるので必要です。
@MainActor
// ObservableObject：SwiftUI の ViewModel として使うためのプロトコル。
// このクラス内の @Published プロパティが変化すると、View が自動で再描画されます。
class PlaybackViewModel: ObservableObject {
    // @Published：変更を監視し、View にその変化を通知するプロパティ包み。
    // private(set) にすることで外部から書き換えできず、ViewModel 内部からだけ更新されます。
    @Published private(set) var current: TranscriptSegment

    // isPlaying：再生中かどうかのフラグ。Play/Pause ボタンの表示切替に使います。
    @Published var isPlaying = false

    // currentTime：現在の再生時刻（秒）。プログレスバーや経過時間表示に使います。
    @Published var currentTime: TimeInterval = 0

    // isAutoplayOn：セクション終了時に自動で次のセクションを再生するかどうかのフラグ。
    @Published var isAutoplayOn = false

    // segments：すべてのセクションデータを保持します。初期化時に渡される配列です。
    private let segments: [TranscriptSegment]
    // player：AVPlayer インスタンス。音声ファイルを再生・制御します。
    private let player: AVPlayer

    // boundaryObserver：セクション終了タイミングを検知するためのオブザーバ保持用。
    private var boundaryObserver: Any?
    // periodicObserver：0.5秒ごとに再生位置を取得するオブザーバ保持用。
    private var periodicObserver: Any?

    /// イニシャライザ（コンストラクタ）
    /// - Parameters:
    ///   - segments: セクションの配列
    ///   - audioURL: 再生する音声ファイルの URL
    ///   - initial: 最初に再生するセクション
    init(segments: [TranscriptSegment], audioURL: URL, initial: TranscriptSegment) {
        // 引数で渡されたセクション配列を保存
        self.segments = segments
        // 初期セクションを current に設定
        self.current  = initial

        // AVPlayerItem を作成して AVPlayer にセット
        let asset = AVURLAsset(url: audioURL)       // AVURLAsset：ファイルを扱うラッパー
        let item  = AVPlayerItem(asset: asset)      // AVPlayerItem：再生アイテム
        self.player = AVPlayer(playerItem: item)    // AVPlayer：再生コントローラ

        // 初期選択セクションの開始時刻にシーク
        seek(to: initial.start)
        // セクション終了時の動作を登録
        addBoundaryObserver()
        // 再生位置を定期的に更新するオブザーバを追加
        addPeriodicTimeObserver()
    }

    // currentIndex：現在のセクションがセクション配列内の何番目か（0ベース）を返します。
    var currentIndex: Int {
        segments.firstIndex { $0.id == current.id } ?? 0
    }

    // progress：プログレスバー表示用。現在位置がセクション全体の何%かを 0.0–1.0 で返します。
    var progress: Double {
        let start = current.start, end = current.end
        guard end > start else { return 0 }
        return min(max((currentTime - start)/(end - start), 0), 1)
    }

    // MARK: - 再生コントロールメソッド

    /// 再生を開始します。
    func play() {
        player.play()
        isPlaying = true
    }

    /// 再生を一時停止します。
    func pause() {
        player.pause()
        isPlaying = false
    }

    /// 次のセクションに切り替えて再生位置を移動します（再生状態は維持）。
    func next() {
        guard let idx = segments.firstIndex(where: { $0.id == current.id }),
              idx + 1 < segments.count else { return }
        switchTo(segments[idx+1])
    }

    /// 前のセクションに切り替えて再生位置を移動します（再生状態は維持）。
    func prev() {
        guard let idx = segments.firstIndex(where: { $0.id == current.id }),
              idx > 0 else { return }
        switchTo(segments[idx-1])
    }

    /// 現在のセクションの先頭にシークし、再生中なら再度再生します。
    func restart() {
        seek(to: current.start)
        if isPlaying { play() }
    }

    /// 5秒戻る。戻す前に一時停止し、必要に応じて再生を再開します。
    func rewind(by seconds: TimeInterval = 5) {
        let wasPlaying = isPlaying
        pause()
        let newTime = max(currentTime - seconds, current.start)
        seek(to: newTime)
        if wasPlaying { play() }
    }

    /// 10秒進む。進める前に一時停止し、必要に応じて再生を再開します。
    func fastForward(by seconds: TimeInterval = 10) {
        let wasPlaying = isPlaying
        pause()
        let newTime = min(currentTime + seconds, current.end)
        seek(to: newTime)
        if wasPlaying { play() }
    }

    // MARK: - 内部ヘルパー

    /// セクションを切り替えて自動再生する場合などに使います。
    private func switchTo(_ seg: TranscriptSegment) {
        current = seg
        seek(to: seg.start)
        if isPlaying { play() }
    }

    /// 指定秒数にシーク（移動）します。currentTime も更新。
    private func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cm)
        currentTime = time
    }

    /// 各セクションの終了時刻に到達したときの挙動を登録します。
    /// isAutoplayOn が true かつ再生中なら next()、それ以外で再生中なら pause()。
    private func addBoundaryObserver() {
        let times = segments.map {
            CMTime(seconds: $0.end, preferredTimescale: 600)
        }
        boundaryObserver = player.addBoundaryTimeObserver(
            forTimes: times as [NSValue],
            queue: .main
        ) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isAutoplayOn && self.isPlaying {
                    self.next()
                } else if self.isPlaying {
                    self.pause()
                }
            }
        }
    }

    /// 0.5秒ごとに現在の再生位置を currentTime に更新します（プログレスバー用）。
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        periodicObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
            }
        }
    }

    /// インスタンス破棄時にオブザーバを解除してリソースを解放します。
    deinit {
        if let obs = boundaryObserver {
            player.removeTimeObserver(obs)
        }
        if let obs = periodicObserver {
            player.removeTimeObserver(obs)
        }
    }
}
