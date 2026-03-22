import Foundation

@Observable
final class TestDebugSession: Identifiable {
    let id: UUID
    var name: String
    var startedAt: Date
    var completedAt: Date?
    var speedMode: SpeedMode
    var targetSite: BuiltInSite
    var concurrency: Int
    var settleDelayMs: Int
    var totalAttempts: Int
    var successCount: Int
    var failCount: Int
    var tempDisabledCount: Int
    var logs: [LogEntry]
    var isRunning: Bool

    init(name: String, speedMode: SpeedMode, targetSite: BuiltInSite, concurrency: Int = 4, settleDelayMs: Int = 2000) {
        self.id = UUID()
        self.name = name
        self.startedAt = Date()
        self.speedMode = speedMode
        self.targetSite = targetSite
        self.concurrency = concurrency
        self.settleDelayMs = settleDelayMs
        self.totalAttempts = 0
        self.successCount = 0
        self.failCount = 0
        self.tempDisabledCount = 0
        self.logs = []
        self.isRunning = true
    }

    var successRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(successCount) / Double(totalAttempts) * 100
    }

    var duration: TimeInterval {
        (completedAt ?? Date()).timeIntervalSince(startedAt)
    }
}
