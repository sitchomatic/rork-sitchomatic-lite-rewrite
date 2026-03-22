import Foundation

nonisolated struct CustomSite: Codable, Sendable, Identifiable {
    let id: String
    var name: String
    var domain: String
    var emailSelector: String
    var passwordSelector: String
    var submitSelector: String
    var addedAt: Date

    init(name: String, domain: String, emailSelector: String, passwordSelector: String, submitSelector: String) {
        self.id = UUID().uuidString
        self.name = name
        self.domain = domain
        self.emailSelector = emailSelector
        self.passwordSelector = passwordSelector
        self.submitSelector = submitSelector
        self.addedAt = Date()
    }

    var selectors: LoginSiteSelectors {
        LoginSiteSelectors(emailSelector: emailSelector, passwordSelector: passwordSelector, submitSelector: submitSelector)
    }
}
