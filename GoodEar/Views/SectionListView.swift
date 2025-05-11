// SectionListView.swift

import SwiftUI

struct SectionListView: View {
    @StateObject private var viewModel: SectionListViewModel
    @State private var showPlayback = false

    init(filePair: FilePair) {
        _viewModel = StateObject(wrappedValue: SectionListViewModel(filePair: filePair))
    }

    var body: some View {
        List {
            ForEach(Array(viewModel.segments.enumerated()), id: \.element.id) { idx, seg in
                Button {
                    viewModel.select(seg)
                    showPlayback = true
                } label: {
                    HStack {
                        Text(
                            String(format: "%03d", idx + 1)
                            + "　"
                            + "\(formatTime(seg.start))–\(formatTime(seg.end))"
                        )
                        Spacer()
                        Image(systemName: viewModel.isPlayed(seg) ? "ear.fill" : "ear")
                            .foregroundColor(viewModel.isPlayed(seg) ? .primary : .secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showPlayback) {
            if let seg = viewModel.selectedSegment {
                // rawSegments を SRT または JSON で読み込む
                let raw = viewModel.filePair.textURL.pathExtension.lowercased() == "srt"
                    ? SRTParsingService.loadSegments(from: viewModel.filePair.textURL)
                    : JSONParsingService.loadRawSegments(from: viewModel.filePair.textURL)
                
                PlaybackModalView(
                    segments:    viewModel.segments,
                    rawSegments: raw,
                    audioURL:    viewModel.filePair.audioURL,
                    initial:     seg,
                    onPlay:      { played in
                        viewModel.markPlayed(played)
                    }
                )
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
