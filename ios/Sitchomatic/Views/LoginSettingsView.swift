import SwiftUI

struct LoginSettingsView: View {
    @Bindable var vm: LoginViewModel

    var body: some View {
        Form {
            Section("Speed Mode") {
                SpeedToggleView(selectedSpeed: $vm.speedMode)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Post Page Settle Delay") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Delay after page load")
                            .font(.subheadline)
                        Spacer()
                        Text("\(vm.postPageSettleDelayMs)ms")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(.cyan)
                    }
                    Slider(value: Binding(
                        get: { Double(vm.postPageSettleDelayMs) },
                        set: { vm.postPageSettleDelayMs = Int($0) }
                    ), in: 0...10000, step: 250)
                    .tint(.cyan)
                    Text("0ms = no extra wait, 10000ms = 10 seconds")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Mode") {
                LabeledContent("Target", value: vm.displayName)
            }

            Section("Concurrency") {
                Stepper("Max Sessions: \(vm.maxConcurrency)", value: $vm.maxConcurrency, in: 1...14)
            }

            Section("Debug") {
                Toggle("Debug Mode", isOn: $vm.debugMode)
            }
        }
        .navigationTitle("Login Settings")
        .onChange(of: vm.speedMode) { _, _ in vm.persistSettings() }
        .onChange(of: vm.maxConcurrency) { _, _ in vm.persistSettings() }
        .onChange(of: vm.debugMode) { _, _ in vm.persistSettings() }
        .onChange(of: vm.postPageSettleDelayMs) { _, _ in vm.persistSettings() }
    }
}
