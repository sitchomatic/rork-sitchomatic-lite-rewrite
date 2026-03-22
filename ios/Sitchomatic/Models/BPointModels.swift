import Foundation

nonisolated struct BPointBiller: Codable, Sendable, Identifiable {
    let id: String
    let code: String
    let name: String
    var isActive: Bool

    init(code: String, name: String, isActive: Bool = true) {
        self.id = code
        self.code = code
        self.name = name
        self.isActive = isActive
    }
}

nonisolated enum CardType: String, Codable, CaseIterable, Sendable {
    case visa = "Visa"
    case mastercard = "Mastercard"

    var selectorPatterns: [String] {
        switch self {
        case .visa:
            return [".visa", "[data-type='visa']", "[aria-label='Visa']", "button.visa", "input[value='visa']"]
        case .mastercard:
            return [".mastercard", "[data-type='mastercard']", "[aria-label='MasterCard']", "button.mastercard", "input[value='mastercard']"]
        }
    }

    var icon: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard"
        }
    }
}

@Observable
final class BPointAttempt: Identifiable {
    let id: UUID
    let billerCode: String
    let billerName: String
    let amount: String
    let cardType: CardType
    var status: BPointAttemptStatus
    var startedAt: Date?
    var completedAt: Date?
    var errorMessage: String?
    var logs: [LogEntry]

    init(billerCode: String, billerName: String, amount: String, cardType: CardType) {
        self.id = UUID()
        self.billerCode = billerCode
        self.billerName = billerName
        self.amount = amount
        self.cardType = cardType
        self.status = .queued
        self.logs = []
    }

    var duration: TimeInterval? {
        guard let start = startedAt else { return nil }
        return (completedAt ?? Date()).timeIntervalSince(start)
    }

    var formattedDuration: String {
        guard let d = duration else { return "—" }
        return String(format: "%.1fs", d)
    }
}

nonisolated enum BPointAttemptStatus: String, Sendable {
    case queued = "Queued"
    case running = "Running"
    case success = "Success"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .queued: return "clock"
        case .running: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

nonisolated enum BPointBillerPool {
    static let defaultBillers: [BPointBiller] = [
        BPointBiller(code: "0100", name: "Telstra"),
        BPointBiller(code: "0200", name: "Optus"),
        BPointBiller(code: "0300", name: "AGL Energy"),
        BPointBiller(code: "0400", name: "Origin Energy"),
        BPointBiller(code: "0500", name: "EnergyAustralia"),
        BPointBiller(code: "0600", name: "Alinta Energy"),
        BPointBiller(code: "0700", name: "Synergy"),
        BPointBiller(code: "0800", name: "Simply Energy"),
        BPointBiller(code: "0900", name: "Red Energy"),
        BPointBiller(code: "1000", name: "Lumo Energy"),
        BPointBiller(code: "1100", name: "ActewAGL"),
        BPointBiller(code: "1200", name: "Ergon Energy"),
        BPointBiller(code: "1300", name: "Ausgrid"),
        BPointBiller(code: "1400", name: "Dodo Power"),
        BPointBiller(code: "1500", name: "Powershop"),
    ]
}
