import Foundation

nonisolated struct LogEntry: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let message: String
    let category: LogCategory
    let level: LogLevel

    init(_ message: String, category: LogCategory = .general, level: LogLevel = .info) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.category = category
        self.level = level
    }

    var formatted: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return "[\(df.string(from: timestamp))] [\(category.rawValue)] \(message)"
    }
}

nonisolated enum LogCategory: String, Sendable {
    case general = "General"
    case login = "Login"
    case bpoint = "BPoint"
    case network = "Network"
    case system = "System"
    case persistence = "Persistence"
}

nonisolated enum LogLevel: String, Sendable {
    case info = "Info"
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case critical = "Critical"
}
