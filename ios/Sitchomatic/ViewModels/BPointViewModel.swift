import Foundation
import WebKit

@Observable
final class BPointViewModel {
    static let shared = BPointViewModel()

    var billers: [BPointBiller] = []
    var attempts: [BPointAttempt] = []
    var isRunning: Bool = false
    var chargeAmount: String = "1.00"
    var selectedCardType: CardType = .visa
    var maxConcurrency: Int = 4
    var speedMode: SpeedMode = .normal
    var completedCount: Int = 0
    var activeSessions: Int = 0

    private let bpointService = BPointService.shared
    private let sessionManager = WebViewSessionManager()
    private let persistence = PersistenceService.shared
    private let logger = DebugLogger.shared
    private let backgroundService = BackgroundTaskService.shared
    private var batchTask: Task<Void, Never>?

    init() {
        billers = persistence.loadBillers()
    }

    var activeBillers: [BPointBiller] {
        billers.filter(\.isActive)
    }

    var successCount: Int {
        attempts.filter { $0.status == .success }.count
    }

    var failCount: Int {
        attempts.filter { $0.status == .failed }.count
    }

    func startBatch(count: Int) {
        guard !isRunning, !activeBillers.isEmpty else { return }
        isRunning = true
        attempts.removeAll()
        completedCount = 0
        activeSessions = 0
        backgroundService.registerRunner()

        logger.log("Starting BPoint batch: \(count) attempts, concurrency: \(maxConcurrency), amount: $\(chargeAmount), card: \(selectedCardType.rawValue)", category: .bpoint, level: .info)

        let capturedAmount = chargeAmount
        let capturedCard = selectedCardType
        let capturedConcurrency = maxConcurrency
        let capturedSpeed = speedMode

        for _ in 0..<count {
            guard let biller = bpointService.randomBiller(from: billers) else { continue }
            let attempt = BPointAttempt(billerCode: biller.code, billerName: biller.name, amount: capturedAmount, cardType: capturedCard)
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

                        self.activeSessions += 1
                        await self.executeBPointAttempt(attempt, speed: capturedSpeed)
                        self.activeSessions = max(0, self.activeSessions - 1)
                        self.completedCount += 1
                        await semaphore.signal()
                    }
                }
            }

            if self.isRunning {
                self.isRunning = false
                let successes = self.attempts.filter { $0.status == .success }.count
                let failures = self.attempts.filter { $0.status == .failed }.count
                self.logger.log("BPoint batch complete: \(successes) succeeded, \(failures) failed", category: .bpoint, level: .success)
            }
            self.activeSessions = 0
            self.backgroundService.unregisterRunner()
        }
    }

    func stop() {
        isRunning = false
        batchTask?.cancel()
        batchTask = nil
        sessionManager.destroyAllSessions()
        for attempt in attempts where attempt.status == .running || attempt.status == .queued {
            attempt.status = .cancelled
        }
        activeSessions = 0
        backgroundService.unregisterRunner()
    }

    func runBPointBatch(count: Int, amount: String, cardType: CardType, concurrency: Int, speed: SpeedMode, onComplete: @escaping (Int, Int) -> Void) {
        backgroundService.registerRunner()

        Task {
            let semaphore = AsyncSemaphore(limit: concurrency)
            var successes = 0
            var failures = 0
            let staggerDelay = staggerDelayForConcurrency(concurrency)

            var batchAttempts: [BPointAttempt] = []
            for _ in 0..<count {
                guard let biller = bpointService.randomBiller(from: billers) else { continue }
                batchAttempts.append(BPointAttempt(billerCode: biller.code, billerName: biller.name, amount: amount, cardType: cardType))
            }

            await withTaskGroup(of: Bool.self) { group in
                for (index, attempt) in batchAttempts.enumerated() {
                    if index > 0 && staggerDelay > 0 {
                        try? await Task.sleep(for: .milliseconds(staggerDelay))
                    }

                    group.addTask {
                        await semaphore.wait()
                        await self.executeBPointAttempt(attempt, speed: speed)
                        let success = attempt.status == .success
                        await semaphore.signal()
                        return success
                    }
                }

                for await success in group {
                    if success { successes += 1 } else { failures += 1 }
                }
            }

            self.backgroundService.unregisterRunner()
            onComplete(successes, failures)
        }
    }

    private func executeBPointAttempt(_ attempt: BPointAttempt, speed: SpeedMode) async {
        attempt.status = .running
        attempt.startedAt = Date()

        let (sessionId, webView) = sessionManager.createSession()

        do {
            guard let url = URL(string: BPointService.paymentURL) else {
                attempt.status = .failed
                attempt.errorMessage = "Invalid URL"
                attempt.completedAt = Date()
                sessionManager.destroySession(sessionId)
                return
            }
            _ = webView.load(URLRequest(url: url, timeoutInterval: 45))

            let loaded = await sessionManager.waitForPageLoad(sessionId, timeout: 30)
            if !loaded {
                try await Task.sleep(for: .seconds(3))
            }

            let lookupJS = bpointService.buildBillerLookupJS(billerCode: attempt.billerCode)
            _ = try await webView.evaluateJavaScript(lookupJS)
            try await Task.sleep(for: .seconds(2))

            let fillJS = bpointService.buildFillFormJS(amount: attempt.amount, cardType: attempt.cardType)
            let resultString = try await webView.evaluateJavaScript(fillJS) as? String

            if let data = resultString?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                attempt.status = status == "success" ? .success : .failed
                attempt.errorMessage = json["error"] as? String
            } else {
                attempt.status = .failed
                attempt.errorMessage = "No result from page"
            }
        } catch {
            attempt.status = Task.isCancelled ? .cancelled : .failed
            attempt.errorMessage = error.localizedDescription
        }

        attempt.completedAt = Date()
        sessionManager.destroySession(sessionId)

        if speed.isDebugMode {
            logger.log("[BPoint] \(attempt.billerName) → \(attempt.status.rawValue) (\(attempt.formattedDuration))", category: .bpoint, level: attempt.status == .success ? .success : .warning)
        }
    }

    private func staggerDelayForConcurrency(_ concurrency: Int) -> Int {
        if concurrency >= 10 { return 500 }
        if concurrency >= 7 { return 300 }
        if concurrency >= 4 { return 150 }
        return 0
    }

    func saveBillers() {
        persistence.saveBillers(billers)
    }

    func toggleBiller(_ biller: BPointBiller) {
        if let idx = billers.firstIndex(where: { $0.id == biller.id }) {
            billers[idx].isActive.toggle()
            saveBillers()
        }
    }

    func resetBillers() {
        billers = BPointBillerPool.defaultBillers
        saveBillers()
    }

    func handleMemoryPressure() {
        if attempts.count > 100 {
            attempts = Array(attempts.suffix(100))
        }
        sessionManager.handleMemoryPressure()
    }
}
