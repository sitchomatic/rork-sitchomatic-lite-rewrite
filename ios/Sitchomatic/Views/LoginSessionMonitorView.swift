import SwiftUI

struct LoginSessionMonitorView: View {
    let vm: LoginViewModel

    var body: some View {
        List {
            if vm.attempts.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Sessions", systemImage: "rectangle.stack")
                    } description: {
                        Text("Start a batch to see live sessions")
                    }
                }
            } else {
                Section {
                    HStack {
                        Label("Total", systemImage: "number")
                        Spacer()
                        Text("\(vm.attempts.count)")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    HStack {
                        Label("Running", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        Text("\(vm.attempts.filter { $0.status == .running }.count)")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                    HStack {
                        Label("Completed", systemImage: "checkmark")
                        Spacer()
                        Text("\(vm.attempts.filter { $0.status.isTerminal }.count)")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Session Overview")
                }

                Section("Attempts") {
                    ForEach(vm.attempts.reversed()) { attempt in
                        HStack(spacing: 10) {
                            Image(systemName: attempt.status.icon)
                                .foregroundStyle(attemptColor(attempt.status))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(attempt.credential.username)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text(attempt.status.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if let error = attempt.errorMessage {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Spacer()

                            Text(attempt.formattedDuration)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sessions")
    }

    private func attemptColor(_ status: LoginAttemptStatus) -> Color {
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
