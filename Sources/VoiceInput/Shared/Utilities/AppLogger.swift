import Foundation
import os

enum AppLogger {
    static let app = Logger(subsystem: "com.example.voiceinput", category: "App")
    static let audio = Logger(subsystem: "com.example.voiceinput", category: "Audio")
    static let speech = Logger(subsystem: "com.example.voiceinput", category: "Speech")
    static let gemini = Logger(subsystem: "com.example.voiceinput", category: "Gemini")
    static let insertion = Logger(subsystem: "com.example.voiceinput", category: "Insertion")
    static let hotkey = Logger(subsystem: "com.example.voiceinput", category: "Hotkey")
    static let permission = Logger(subsystem: "com.example.voiceinput", category: "Permission")
}
