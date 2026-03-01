import SwiftUI

struct RecorderStatusView: View {
    let state: AppState
    let transcript: String
    let formattedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("状態")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(state.rawValue)
                    .font(.caption.weight(.semibold))
            }

            GroupBox("リアルタイム文字起こし") {
                ScrollView {
                    Text(transcript.isEmpty ? "ここに文字起こしが表示されます" : transcript)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
                .frame(height: 80)
            }

            GroupBox("整形結果") {
                ScrollView {
                    Text(formattedText.isEmpty ? "整形後テキスト" : formattedText)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
                .frame(height: 80)
            }
        }
    }
}
