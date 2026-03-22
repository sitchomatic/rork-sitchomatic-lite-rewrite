import Foundation

@Observable
final class JoePointViewModel {
    static let shared = JoePointViewModel()

    var isRunning: Bool = false
    var loginSite: BuiltInSite = .joe
    var loginConcurrency: Int = 7
    var bpointConcurrency: Int = 7
    var speedMode: SpeedMode = .normal
    var postPageSettleDelayMs: Int = 2000
    var bpointBatchCount: Int = 7
    var chargeAmount: String = "1.00"
    var selectedCardType: CardType = .visa

    var loginCompleted: Int = 0
    var loginSuccesses: Int = 0
    var loginFailures: Int = 0
    var loginDisabled: Int = 0

    var bpointCompleted: Int = 0
    var bpointSuccesses: Int = 0
    var bpointFailures: Int = 0

    var totalSessions: Int = 0
    var loginActiveSessions: Int = 0
    var bpointActiveSessions: Int = 0
    var statusMessage: String = "Ready"
    var elapsedTime: TimeInterval = 0

    private let backgroundService = BackgroundTaskService.shared
    private let logger = DebugLogger.shared
    private var runTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var startTime: Date?

    var totalConcurrency: Int {
        loginConcurrency + bpointConcurrency
    }

    var totalActiveSessions: Int {
        loginActiveSessions + bpointActiveSessions
    }

    func start() {
        guard !isRunning else { return }

        let loginVM = loginSite == .joe ? LoginViewModel.joe : LoginViewModel.ignition
        let toTest = loginVM.credentials.filter { $0.status == .untested || $0.status == .unsure }
        guard !toTest.isEmpty || bpointBatchCount > 0 else { return }

        isRunning = true
        loginCompleted = 0
        loginSuccesses = 0
        loginFailures = 0
        loginDisabled = 0
        bpointCompleted = 0
        bpointSuccesses = 0
        bpointFailures = 0
        loginActiveSessions = 0
        bpointActiveSessions = 0
        totalSessions = min(toTest.count, loginConcurrency) + min(bpointBatchCount, bpointConcurrency)
        statusMessage = "Running JoePoint mode..."
        startTime = Date()
        elapsedTime = 0
        backgroundService.registerRunner()

        startTimer()

        logger.log("[JoePoint] Starting combined mode: \(toTest.count) logins + \(bpointBatchCount) BPoint, total concurrency: \(totalConcurrency)", category: .system, level: .info)

        let capturedSite = loginSite
        let capturedSpeed = speedMode
        let capturedLoginConc = loginConcurrency
        let capturedBPConc = bpointConcurrency
        let capturedSettleDelay = postPageSettleDelayMs
        let capturedBPCount = bpointBatchCount
        let capturedAmount = chargeAmount
        let capturedCard = selectedCardType

        runTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let vm = capturedSite == .joe ? LoginViewModel.joe : LoginViewModel.ignition
                    let creds = vm.credentials.filter { $0.status == .untested || $0.status == .unsure }
                    guard !creds.isEmpty else { return }

                    vm.runTestBatch(
                        credentials: creds,
                        site: capturedSite,
                        speed: capturedSpeed,
                        concurrency: capturedLoginConc,
                        settleDelay: capturedSettleDelay
                    ) { successes, failures, disabled in
                        self.loginCompleted = successes + failures + disabled
                        self.loginSuccesses = successes
                        self.loginFailures = failures
                        self.loginDisabled = disabled
                    }
                }

                if capturedBPCount > 0 {
                    group.addTask {
                        let bpVM = BPointViewModel.shared
                        guard !bpVM.activeBillers.isEmpty else { return }

                        bpVM.runBPointBatch(
                            count: capturedBPCount,
                            amount: capturedAmount,
                            cardType: capturedCard,
                            concurrency: capturedBPConc,
                            speed: capturedSpeed
                        ) { successes, failures in
                            self.bpointCompleted = successes + failures
                            self.bpointSuccesses = successes
                            self.bpointFailures = failures
                        }
                    }
                }
            }

            self.isRunning = false
            self.statusMessage = "Complete"
            self.stopTimer()
            self.backgroundService.unregisterRunner()
            self.logger.log("[JoePoint] Complete: Login \(self.loginSuccesses)W/\(self.loginFailures)F/\(self.loginDisabled)D | BPoint \(self.bpointSuccesses)W/\(self.bpointFailures)F | \(String(format: "%.1fs", self.elapsedTime))", category: .system, level: .success)
        }
    }

    func stop() {
        isRunning = false
        runTask?.cancel()
        runTask = nil
        statusMessage = "Stopped"
        stopTimer()

        let loginVM = loginSite == .joe ? LoginViewModel.joe : LoginViewModel.ignition
        if loginVM.isRunning { loginVM.stopBatch() }
        let bpVM = BPointViewModel.shared
        if bpVM.isRunning { bpVM.stop() }

        loginActiveSessions = 0
        bpointActiveSessions = 0
        backgroundService.unregisterRunner()
        logger.log("[JoePoint] Stopped by user", category: .system, level: .warning)
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && isRunning {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { break }
                if let start = startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
                let loginVM = loginSite == .joe ? LoginViewModel.joe : LoginViewModel.ignition
                loginActiveSessions = loginVM.activeSessions
                bpointActiveSessions = BPointViewModel.shared.activeSessions
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
