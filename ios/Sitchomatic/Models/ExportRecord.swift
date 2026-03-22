import Foundation

nonisolated struct ExportRecord: Codable, Sendable, Identifiable {
    let id: String
    let exportedAt: Date
    let type: String
    let count: Int
    let format: String

    init(type: String, count: Int, format: String) {
        self.id = UUID().uuidString
        self.exportedAt = Date()
        self.type = type
        self.count = count
        self.format = format
    }
}
