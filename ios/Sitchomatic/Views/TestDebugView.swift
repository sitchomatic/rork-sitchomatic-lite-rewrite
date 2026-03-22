import SwiftUI

struct TestDebugView: View {
    @State private var joeVM = LoginViewModel.joe
    @State private var ignitionVM = LoginViewModel.ignition
    @State private var sessions: [TestDebugSession] = []
    @State private var isRunning: Bool = false
    @State private var selectedSpeedForTest: SpeedMode = .normal
    @State private var selectedSiteForTest: BuiltInSite = .joe
    @State private var testCredentialCount: Int = 3
    @State private var testConcurrency: Int = 4
    @State private var testSettleDelay: Int = 2000

    private var activeVM: LoginViewModel {
        selectedSiteForTest == .joe ? joeVM : ignitionVM
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    optimizerHeader
                    configSection
                    quickPresetsSection

                    if !sessions.isEmpty {
                        sessionsSection
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Test & Debug")
        }
    }

    private var optimizerHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .font(.title)
                .foregroundStyle(.purple)
            Text("Test & Debug Optimizer")
                .font(.headline)
            Text("Test different speed modes, settle delays, and concurrency to find the optimal config for 14+ sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var configSection: some View {
        VStack(spacing: 12) {
            Picker("Site", selection: $selectedSiteForTest) {
                ForEach(BuiltInSite.allCases, id: \.rawValue) { site in
                    Text(site.displayName).tag(site)
                }
            }
            .pickerStyle(.segmented)

            SpeedToggleView(selectedSpeed: $selectedSpeedForTest)

            Stepper("Test Credentials: \(testCredentialCount)", value: $testCredentialCount, in: 1...20)
                .font(.subheadline)

            HStack {
                Text("Concurrency")
                    .font(.subheadline)
                Spacer()
                Stepper("\(testConcurrency)", value: $testConcurrency, in: 1...14)
                    .font(.system(.body, design: .monospaced, weight: .bold))
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Post Page Settle")
                        .font(.subheadline)
                    Spacer()
                    Text("\(testSettleDelay)ms")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                }
                Slider(value: Binding(
                    get: { Double(testSettleDelay) },
                    set: { testSettleDelay = Int($0) }
                ), in: 0...10000, step: 250)
                .tint(.cyan)
            }

            Button {
                startTestSession()
            } label: {
                Label(isRunning ? "Running..." : "Run Test", systemImage: isRunning ? "hourglass" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isRunning || activeVM.credentials.count < testCredentialCount)

            if activeVM.credentials.count < testCredentialCount {
                Text("Need at least \(testCredentialCount) credentials on \(selectedSiteForTest.displayName) (have \(activeVM.credentials.count))")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Presets")
                .font(.subheadline.bold())

            HStack(spacing: 12) {
                PresetButton(title: "Speed Demon", icon: "bolt.horizontal.fill", color: .red) {
                    selectedSpeedForTest = .speedDemon
                    testConcurrency = 14
                    testSettleDelay = 500
                }
                PresetButton(title: "Slow Debug", icon: "ant.fill", color: .green) {
                    selectedSpeedForTest = .slowDebug
                    testConcurrency = 2
                    testSettleDelay = 3000
                }
            }

            HStack(spacing: 12) {
                PresetButton(title: "Max Conc.", icon: "arrow.3.trianglepath", color: .cyan) {
                    selectedSpeedForTest = .fast
                    testConcurrency = 14
                    testSettleDelay = 1000
                }
                PresetButton(title: "Balanced", icon: "gauge.with.dots.needle.50percent", color: .blue) {
                    selectedSpeedForTest = .normal
                    testConcurrency = 7
                    testSettleDelay = 2000
                }
            }

            Text("Optimizer ranks Speed Demon and Slow Debug highest for testing")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Test Sessions")
                    .font(.subheadline.bold())
                Spacer()
                if sessions.count > 1 {
                    Button("Clear") {
                        sessions.removeAll(where: { !$0.isRunning })
                    }
                    .font(.caption)
                }
            }

            ForEach(sessions.reversed()) { session in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(session.name)
                            .font(.subheadline.bold())
                        Spacer()
                        if session.isRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(session.speedMode.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(session.speedMode.color.opacity(0.15))
                            .foregroundStyle(session.speedMode.color)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 4) {
                        Image(systemName: session.targetSite.icon)
                            .font(.caption2)
                            .foregroundStyle(session.targetSite == .joe ? .green : .orange)
                        Text(session.targetSite.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("• \(session.concurrency) conc")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("• \(session.settleDelayMs)ms settle")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 16) {
                        Label("\(session.successCount)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Label("\(session.failCount)", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Label("\(session.tempDisabledCount)", systemImage: "clock.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)

                    if session.totalAttempts > 0 {
                        Text(String(format: "%.1f%% success rate • %.1fs • %d tested", session.successRate, session.duration, session.totalAttempts))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if session.isRunning {
                        Text("Running concurrent tests...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func startTestSession() {
        guard !isRunning else { return }

        let vm = activeVM
        let testCreds = Array(vm.credentials.prefix(testCredentialCount))
        guard testCreds.count >= testCredentialCount else { return }

        let session = TestDebugSession(name: "Test \(sessions.count + 1)", speedMode: selectedSpeedForTest, targetSite: selectedSiteForTest, concurrency: testConcurrency, settleDelayMs: testSettleDelay)
        sessions.append(session)
        isRunning = true

        let capturedSite = selectedSiteForTest
        let capturedSpeed = selectedSpeedForTest
        let capturedConcurrency = testConcurrency
        let capturedSettleDelay = testSettleDelay

        vm.runTestBatch(credentials: testCreds, site: capturedSite, speed: capturedSpeed, concurrency: capturedConcurrency, settleDelay: capturedSettleDelay) { successes, failures, disabled in
            session.totalAttempts = successes + failures + disabled
            session.successCount = successes
            session.failCount = failures
            session.tempDisabledCount = disabled
            session.completedAt = Date()
            session.isRunning = false
            isRunning = false
        }
    }
}

struct PresetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
