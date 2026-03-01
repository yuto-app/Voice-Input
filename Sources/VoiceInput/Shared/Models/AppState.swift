import Foundation

enum AppState: String {
    case idle = "Idle"
    case listening = "Listening"
    case transcribing = "Transcribing"
    case processing = "Processing"
    case inserting = "Inserting"
    case error = "Error"
}
