import SwiftUI

struct SettingsView: View {
    @State private var joeVM = LoginViewModel.joe
    @State private var ignitionVM = LoginViewModel.ignition
    @State private var bpVM = BPointViewModel.shared
    @State private var showClearConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Joe Fortune") {
                    SpeedToggleView(selectedSpeed: $joeVM.speedMode)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                    Stepper("Max Concurrency: \(joeVM.maxConcurrency)", value: $joeVM.maxConcurrency, in: 1...14)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Post Page Settle")
                                .font(.subheadline)
                            Spacer()
                            Text("\(joeVM.postPageSettleDelayMs)ms")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: Binding(
                            get: { Double(joeVM.postPageSettleDelayMs) },
                            set: { joeVM.postPageSettleDelayMs = Int($0) }
                        ), in: 0...10000, step: 250)
                        .tint(.cyan)
                    }

                    Toggle("Debug Mode", isOn: $joeVM.debugMode)

                    LabeledContent("Credentials", value: "\(joeVM.credentials.count)")
                }

                Section("Ignition Casino") {
                    SpeedToggleView(selectedSpeed: $ignitionVM.speedMode)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                    Stepper("Max Concurrency: \(ignitionVM.maxConcurrency)", value: $ignitionVM.maxConcurrency, in: 1...14)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Post Page Settle")
                                .font(.subheadline)
                            Spacer()
                            Text("\(ignitionVM.postPageSettleDelayMs)ms")
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                        Slider(value: Binding(
                            get: { Double(ignitionVM.postPageSettleDelayMs) },
                            set: { ignitionVM.postPageSettleDelayMs = Int($0) }
                        ), in: 0...10000, step: 250)
                        .tint(.cyan)
                    }

                    Toggle("Debug Mode", isOn: $ignitionVM.debugMode)

                    LabeledContent("Credentials", value: "\(ignitionVM.credentials.count)")
                }

                Section("BPoint") {
                    HStack {
                        Text("Charge Amount")
                        Spacer()
                        TextField("1.00", text: $bpVM.chargeAmount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }

                    Picker("Card Type", selection: $bpVM.selectedCardType) {
                        ForEach(CardType.allCases, id: \.rawValue) { card in
                            Text(card.rawValue).tag(card)
                        }
                    }

                    Stepper("Max Concurrency: \(bpVM.maxConcurrency)", value: $bpVM.maxConcurrency, in: 1...14)
                }

                Section("Background") {
                    let bgService = BackgroundTaskService.shared
                    HStack {
                        Text("Active Runners")
                        Spacer()
                        Text("\(bgService.runnerCount)")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(bgService.runnerCount > 0 ? .green : .secondary)
                    }
                    HStack {
                        Text("Screen Lock Prevention")
                        Spacer()
                        Image(systemName: bgService.isKeepingAwake ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(bgService.isKeepingAwake ? .green : .secondary)
                    }
                }

                Section("Data Management") {
                    Button("Clear Joe Fortune Credentials", role: .destructive) {
                        joeVM.clearAllCredentials()
                    }
                    .disabled(joeVM.credentials.isEmpty)

                    Button("Clear Ignition Credentials", role: .destructive) {
                        ignitionVM.clearAllCredentials()
                    }
                    .disabled(ignitionVM.credentials.isEmpty)

                    Button("Clear All Credentials", role: .destructive) {
                        showClearConfirmation = true
                    }
                    .disabled(joeVM.credentials.isEmpty && ignitionVM.credentials.isEmpty)

                    Button("Reset BPoint Billers") {
                        bpVM.resetBillers()
                    }

                    Button("Clear Debug Logs") {
                        DebugLogger.shared.clear()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "3.0.0")
                    LabeledContent("Build", value: "JoePoint + 14 Concurrent")
                    LabeledContent("Target", value: "iOS 18+")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onChange(of: joeVM.speedMode) { _, _ in joeVM.persistSettings() }
            .onChange(of: joeVM.maxConcurrency) { _, _ in joeVM.persistSettings() }
            .onChange(of: joeVM.debugMode) { _, _ in joeVM.persistSettings() }
            .onChange(of: joeVM.postPageSettleDelayMs) { _, _ in joeVM.persistSettings() }
            .onChange(of: ignitionVM.speedMode) { _, _ in ignitionVM.persistSettings() }
            .onChange(of: ignitionVM.maxConcurrency) { _, _ in ignitionVM.persistSettings() }
            .onChange(of: ignitionVM.debugMode) { _, _ in ignitionVM.persistSettings() }
            .onChange(of: ignitionVM.postPageSettleDelayMs) { _, _ in ignitionVM.persistSettings() }
            .alert("Clear All Credentials?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    joeVM.clearAllCredentials()
                    ignitionVM.clearAllCredentials()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all credentials from both Joe Fortune and Ignition Casino. This cannot be undone.")
            }
        }
    }
}
