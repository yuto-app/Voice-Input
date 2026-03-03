import SwiftUI

struct RecordingHUDView: View {
    @ObservedObject var appController: AppController
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .opacity(pulse ? 0.25 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)

            VStack(alignment: .leading, spacing: 3) {
                Text(statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                if !appController.liveTranscript.isEmpty {
                    Text(String(appController.liveTranscript.suffix(60)))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: 280, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { pulse = true }
    }

    private var statusLabel: String {
        switch appController.state {
        case .listening: return "● 録音中"
        case .transcribing: return "● 文字起こし中"
        default: return ""
        }
    }
}
