import SwiftUI

struct LoginDashboardView: View {
    let vm: LoginViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                speedBadge
                statsGrid
                batchControlSection
                concurrencySlider
                settleDelaySlider
                if !vm.attempts.isEmpty {
                    recentAttemptsSection
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vm.displayName)
    }

    private var speedBadge: some View {
        HStack {
            Image(systemName: vm.speedMode.icon)
                .foregroundStyle(vm.speedMode.color)
            Text("Speed: \(vm.speedMode.rawValue)")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(vm.speedMode.color)
            Spacer()
            if vm.activeSessions > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("\(vm.activeSessions) live")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
            }
            Text("\(vm.credentials.count) paired credentials")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(vm.speedMode.color.opacity(0.1))
        .clipShape(.rect(cornerRadius: 10))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Working", value: "\(vm.workingCredentials.count)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Temp Dis", value: "\(vm.tempDisabledCredentials.count)", icon: "clock.fill", color: .orange)
            StatCard(title: "Perm Dis", value: "\(vm.permDisabledCredentials.count)", icon: "xmark.octagon.fill", color: .red)
            StatCard(title: "Untested", value: "\(vm.untestedCredentials.count)", icon: "questionmark.circle", color: .secondary)
        }
    }

    private var batchControlSection: some View {
        VStack(spacing: 12) {
            if vm.isRunning {
                HStack {
                    ProgressView()
                        .tint(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Running \(vm.completedCount)/\(vm.attempts.count)")
                            .font(.subheadline.bold())
                        Text("\(vm.activeSessions) active sessions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Stop", role: .destructive) {
                        vm.stopBatch()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                Button {
                    vm.startBatch()
                } label: {
                    Label("Start Batch", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(vm.untestedCredentials.isEmpty && vm.credentials.filter { $0.status == .unsure }.isEmpty)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var concurrencySlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Concurrency")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(vm.maxConcurrency)")
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(.cyan)
            }
            HStack(spacing: 12) {
                Button {
                    withAnimation { vm.maxConcurrency = max(1, vm.maxConcurrency - 1) }
                    vm.persistSettings()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }

                GeometryReader { geo in
                    let progress = CGFloat(vm.maxConcurrency - 1) / 13.0
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemGroupedBackground))
                        Capsule()
                            .fill(LinearGradient(colors: [.cyan, .cyan.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress)
                    }
                    .frame(height: 8)
                    .frame(maxHeight: .infinity, alignment: .center)
                }

                Button {
                    withAnimation { vm.maxConcurrency = min(14, vm.maxConcurrency + 1) }
                    vm.persistSettings()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }
            }
            .frame(height: 32)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var settleDelaySlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Post Page Settle Delay")
                    .font(.subheadline.bold())
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
            .onChange(of: vm.postPageSettleDelayMs) { _, _ in
                vm.persistSettings()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var recentAttemptsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Attempts")
                .font(.subheadline.bold())

            ForEach(vm.attempts.suffix(20).reversed()) { attempt in
                HStack {
                    Image(systemName: attempt.status.icon)
                        .foregroundStyle(colorForStatus(attempt.status))
                    Text(attempt.credential.username)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(attempt.status.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(attempt.formattedDuration)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func colorForStatus(_ status: LoginAttemptStatus) -> Color {
        switch status {
        case .success: return .green
        case .tempDisabled: return .orange
        case .permDisabled, .failed: return .red
        case .running: return .blue
        case .cancelled: return .gray
        case .noAccount: return .secondary
        case .queued: return .secondary
        case .unsure: return .yellow
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
