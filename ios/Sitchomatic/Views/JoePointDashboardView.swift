import SwiftUI

struct JoePointDashboardView: View {
    @State private var vm = JoePointViewModel.shared
    @State private var joeVM = LoginViewModel.joe
    @State private var ignitionVM = LoginViewModel.ignition
    @State private var bpVM = BPointViewModel.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerBadge
                    configSection
                    controlSection
                    if vm.isRunning || vm.loginCompleted > 0 || vm.bpointCompleted > 0 {
                        resultsSection
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("JoePoint Mode")
        }
    }

    private var headerBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse, options: .repeating, isActive: vm.isRunning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Combined Login + BPoint")
                    .font(.subheadline.bold())
                Text("Up to \(vm.totalConcurrency) concurrent sessions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if vm.isRunning {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("\(vm.totalActiveSessions) live")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                    Text(String(format: "%.0fs", vm.elapsedTime))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            } else if BackgroundTaskService.shared.isKeepingAwake {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.yellow.opacity(0.15), .orange.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(.rect(cornerRadius: 12))
    }

    private var configSection: some View {
        VStack(spacing: 12) {
            Picker("Login Site", selection: $vm.loginSite) {
                ForEach(BuiltInSite.allCases, id: \.rawValue) { site in
                    Text(site.displayName).tag(site)
                }
            }
            .pickerStyle(.segmented)

            SpeedToggleView(selectedSpeed: $vm.speedMode)

            HStack {
                Text("Login Concurrency")
                    .font(.subheadline)
                Spacer()
                Stepper("\(vm.loginConcurrency)", value: $vm.loginConcurrency, in: 1...14)
                    .font(.system(.body, design: .monospaced, weight: .bold))
            }

            HStack {
                Text("BPoint Concurrency")
                    .font(.subheadline)
                Spacer()
                Stepper("\(vm.bpointConcurrency)", value: $vm.bpointConcurrency, in: 1...14)
                    .font(.system(.body, design: .monospaced, weight: .bold))
            }

            HStack {
                Text("BPoint Batch Count")
                    .font(.subheadline)
                Spacer()
                Stepper("\(vm.bpointBatchCount)", value: $vm.bpointBatchCount, in: 0...50)
                    .font(.system(.body, design: .monospaced, weight: .bold))
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Post Page Settle")
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
            }

            HStack {
                Text("Amount ($)")
                    .font(.subheadline)
                Spacer()
                TextField("1.00", text: $vm.chargeAmount)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }

            Picker("Card", selection: $vm.selectedCardType) {
                ForEach(CardType.allCases, id: \.rawValue) { card in
                    Text(card.rawValue).tag(card)
                }
            }
            .pickerStyle(.segmented)

            let activeLoginVM = vm.loginSite == .joe ? joeVM : ignitionVM
            HStack {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(.secondary)
                Text("\(activeLoginVM.credentials.filter { $0.status == .untested || $0.status == .unsure }.count) untested logins")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(bpVM.activeBillers.count) billers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var controlSection: some View {
        VStack(spacing: 12) {
            if vm.isRunning {
                HStack {
                    ProgressView()
                        .tint(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.statusMessage)
                            .font(.subheadline.bold())
                        Text("Login: \(vm.loginCompleted) done (\(vm.loginActiveSessions) live) | BPoint: \(vm.bpointCompleted) done (\(vm.bpointActiveSessions) live)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Stop", role: .destructive) {
                        vm.stop()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                Button {
                    vm.start()
                } label: {
                    Label("Start JoePoint Batch", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.subheadline.bold())
                Spacer()
                if vm.elapsedTime > 0 {
                    Text(String(format: "%.1fs elapsed", vm.elapsedTime))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text("Login")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        MiniStat(value: "\(vm.loginSuccesses)", label: "W", color: .green)
                        MiniStat(value: "\(vm.loginFailures)", label: "F", color: .red)
                        MiniStat(value: "\(vm.loginDisabled)", label: "D", color: .orange)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("BPoint")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        MiniStat(value: "\(vm.bpointSuccesses)", label: "W", color: .green)
                        MiniStat(value: "\(vm.bpointFailures)", label: "F", color: .red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct MiniStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }
}
