import SwiftUI

struct MainMenuView: View {
    @Binding var activeMode: ActiveAppMode?
    var requiresProfileSelection: Bool = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    backgroundIndicator

                    LazyVGrid(columns: columns, spacing: 16) {
                        MainMenuCard(title: "Joe Fortune", icon: "bolt.shield.fill", color: .green, subtitle: "Login Testing") {
                            activeMode = .joe
                        }
                        MainMenuCard(title: "Ignition Casino", icon: "flame.fill", color: .orange, subtitle: "Login Testing") {
                            activeMode = .ignition
                        }
                        MainMenuCard(title: "BPoint", icon: "creditcard.fill", color: .blue, subtitle: "Payment Automation") {
                            activeMode = .bpoint
                        }
                        MainMenuCard(title: "JoePoint", icon: "bolt.trianglebadge.exclamationmark.fill", color: .yellow, subtitle: "Combined Mode") {
                            activeMode = .joePoint
                        }
                        MainMenuCard(title: "Test & Debug", icon: "hammer.fill", color: .purple, subtitle: "Optimizer") {
                            activeMode = .testDebug
                        }
                        MainMenuCard(title: "Debug Log", icon: "doc.text.magnifyingglass", color: .teal, subtitle: "System Logs") {
                            activeMode = .debugLog
                        }
                        MainMenuCard(title: "Vault", icon: "lock.shield.fill", color: .indigo, subtitle: "Storage & Export") {
                            activeMode = .vault
                        }
                        MainMenuCard(title: "Settings", icon: "gearshape.fill", color: .gray, subtitle: "Configuration") {
                            activeMode = .settings
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sitchomatic")
            .preferredColorScheme(.dark)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.green)
                .symbolEffect(.pulse, options: .repeating)

            Text("Sitchomatic")
                .font(.largeTitle.bold())

            Text("14+ Concurrent Sessions • Stable • Fast")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var backgroundIndicator: some View {
        let bgService = BackgroundTaskService.shared
        if bgService.runnerCount > 0 {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse, options: .repeating)
                Text("\(bgService.runnerCount) active runner(s)")
                    .font(.caption.bold())
                Text("• Screen locked on")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())
            .padding(.horizontal)
        }
    }
}

struct MainMenuCard: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
