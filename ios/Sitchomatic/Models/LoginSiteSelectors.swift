import Foundation

nonisolated struct LoginSiteSelectors: Sendable {
    let emailSelector: String
    let passwordSelector: String
    let submitSelector: String
    let disabledKeywords: [String] = [
        "has been disabled", "temporarily disabled", "account is disabled",
        "blocked", "suspended", "permanently disabled", "blacklisted",
        "account closed", "too many attempts", "try again later"
    ]
}

nonisolated enum BuiltInSite: String, CaseIterable, Sendable {
    case joe = "joefortunepokies.win"
    case ignition = "ignitioncasino.ooo"

    var selectors: LoginSiteSelectors {
        switch self {
        case .joe:
            return LoginSiteSelectors(emailSelector: "#username", passwordSelector: "#password", submitSelector: "#loginSubmit")
        case .ignition:
            return LoginSiteSelectors(emailSelector: "#email", passwordSelector: "#login-password", submitSelector: "#login-submit")
        }
    }

    var displayName: String {
        switch self {
        case .joe: return "Joe Fortune"
        case .ignition: return "Ignition Casino"
        }
    }

    var baseURL: String {
        "https://\(rawValue)"
    }

    var icon: String {
        switch self {
        case .joe: return "bolt.shield.fill"
        case .ignition: return "flame.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .joe: return "green"
        case .ignition: return "orange"
        }
    }
}
