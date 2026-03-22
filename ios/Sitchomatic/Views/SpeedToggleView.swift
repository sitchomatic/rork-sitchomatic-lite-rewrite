import SwiftUI

struct SpeedToggleView: View {
    @Binding var selectedSpeed: SpeedMode

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Speed Mode")
                    .font(.subheadline.bold())
                Spacer()
                Text(selectedSpeed.rawValue)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(selectedSpeed.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedSpeed.color.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 4) {
                ForEach(SpeedMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedSpeed = mode
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                            Text(mode == .speedDemon ? "🔥" : mode == .slowDebug ? "🐞" : "")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedSpeed == mode ? mode.color.opacity(0.2) : Color.clear)
                        .foregroundStyle(selectedSpeed == mode ? mode.color : .secondary)
                        .clipShape(.rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            delayPreview
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var delayPreview: some View {
        HStack(spacing: 16) {
            DelayChip(label: "Type", value: "\(selectedSpeed.typingDelayMs)ms")
            DelayChip(label: "Action", value: "\(selectedSpeed.actionDelayMs)ms")
            DelayChip(label: "Submit", value: "\(selectedSpeed.postSubmitWaitMs)ms")
            if selectedSpeed.isDebugMode {
                Text("DEBUG")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.indigo.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(.secondary)
    }
}

private struct DelayChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(.caption2, design: .default))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(.caption2, design: .monospaced, weight: .medium))
        }
    }
}
