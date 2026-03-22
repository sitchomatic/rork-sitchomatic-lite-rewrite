import SwiftUI

struct BPointDashboardView: View {
    @State private var bpVM = BPointViewModel.shared
    @State private var batchCount: Int = 5
    @State private var showBillerManager: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    configSection
                    concurrencySection
                    controlSection
                    if !bpVM.attempts.isEmpty {
                        attemptsSection
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("BPoint")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showBillerManager = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
            .sheet(isPresented: $showBillerManager) {
                BillerManagerSheet(billers: $bpVM.billers) {
                    bpVM.saveBillers()
                }
            }
        }
    }

    private var configSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Config")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(bpVM.activeBillers.count) billers active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Amount ($)")
                    .font(.subheadline)
                Spacer()
                TextField("1.00", text: $bpVM.chargeAmount)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }

            HStack {
                Text("Card Type")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $bpVM.selectedCardType) {
                    ForEach(CardType.allCases, id: \.rawValue) { card in
                        Text(card.rawValue).tag(card)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            Stepper("Batch Count: \(batchCount)", value: $batchCount, in: 1...50)
                .font(.subheadline)

            SpeedToggleView(selectedSpeed: $bpVM.speedMode)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var concurrencySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Concurrency")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(bpVM.maxConcurrency)")
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(.cyan)
                if bpVM.activeSessions > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("\(bpVM.activeSessions) live")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
            HStack(spacing: 12) {
                Button {
                    withAnimation { bpVM.maxConcurrency = max(1, bpVM.maxConcurrency - 1) }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Circle())
                }

                GeometryReader { geo in
                    let progress = CGFloat(bpVM.maxConcurrency - 1) / 13.0
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
                    withAnimation { bpVM.maxConcurrency = min(14, bpVM.maxConcurrency + 1) }
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

    private var controlSection: some View {
        VStack(spacing: 12) {
            if bpVM.isRunning {
                HStack {
                    ProgressView().tint(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Running \(bpVM.completedCount)/\(bpVM.attempts.count)")
                            .font(.subheadline.bold())
                        Text("\(bpVM.activeSessions) active sessions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Stop", role: .destructive) { bpVM.stop() }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            } else {
                Button {
                    bpVM.startBatch(count: batchCount)
                } label: {
                    Label("Start BPoint Batch", systemImage: "creditcard.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(bpVM.activeBillers.isEmpty)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var attemptsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Attempts")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(bpVM.successCount)W / \(bpVM.failCount)F")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ForEach(bpVM.attempts.suffix(30).reversed()) { attempt in
                HStack(spacing: 10) {
                    Image(systemName: attempt.status.icon)
                        .foregroundStyle(attemptColor(attempt.status))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(attempt.billerName) (\(attempt.billerCode))")
                            .font(.caption).lineLimit(1)
                        HStack(spacing: 4) {
                            Text("$\(attempt.amount)")
                                .font(.caption2)
                            Text("•")
                                .font(.caption2).foregroundStyle(.tertiary)
                            Text(attempt.cardType.rawValue)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(attempt.status.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(attempt.formattedDuration)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func attemptColor(_ status: BPointAttemptStatus) -> Color {
        switch status {
        case .success: return .green
        case .failed: return .red
        case .running: return .blue
        case .cancelled: return .gray
        case .queued: return .secondary
        }
    }
}

struct BillerManagerSheet: View {
    @Binding var billers: [BPointBiller]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Active Billers (\(billers.filter(\.isActive).count))") {
                    ForEach($billers) { $biller in
                        HStack {
                            Toggle(isOn: $biller.isActive) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(biller.name).font(.subheadline)
                                    Text("Code: \(biller.code)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Biller Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
