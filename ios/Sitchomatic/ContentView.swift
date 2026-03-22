import SwiftUI

struct ContentView: View {
    @State private var activeMode: ActiveAppMode?
    @State private var hasEverOpenedJoe: Bool = false
    @State private var hasEverOpenedIgnition: Bool = false
    @State private var showingMenu: Bool = true

    private var persistentModes: Set<ActiveAppMode> { [.joe, .ignition] }

    var body: some View {
        ZStack {
            if hasEverOpenedJoe {
                LoginContentView(initialMode: .joe)
                    .opacity(activeMode == .joe ? 1 : 0)
                    .allowsHitTesting(activeMode == .joe)
            }

            if hasEverOpenedIgnition {
                LoginContentView(initialMode: .ignition)
                    .opacity(activeMode == .ignition ? 1 : 0)
                    .allowsHitTesting(activeMode == .ignition)
            }

            if let mode = activeMode, !persistentModes.contains(mode) {
                nonPersistentModeView(mode)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }

            if showingMenu {
                MainMenuView(activeMode: $activeMode)
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.15), value: activeMode)
        .onChange(of: activeMode) { _, newValue in
            withAnimation {
                showingMenu = newValue == nil
            }
            if let mode = newValue {
                switch mode {
                case .joe: hasEverOpenedJoe = true
                case .ignition: hasEverOpenedIgnition = true
                default: break
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if activeMode != nil && !showingMenu {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        if persistentModes.contains(activeMode!) {
                            showingMenu = true
                        } else {
                            activeMode = nil
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 52)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            LoginViewModel.joe.persistCredentials()
            LoginViewModel.ignition.persistCredentials()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LoginViewModel.joe.persistCredentials()
            LoginViewModel.ignition.persistCredentials()
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func nonPersistentModeView(_ mode: ActiveAppMode) -> some View {
        switch mode {
        case .bpoint:
            BPointDashboardView()
                .withMenuButton { goBack() }
        case .joePoint:
            JoePointDashboardView()
                .withMenuButton { goBack() }
        case .debugLog:
            NavigationStack {
                DebugLogView()
            }
            .withMenuButton { goBack() }
        case .vault:
            NavigationStack {
                VaultView()
            }
            .withMenuButton { goBack() }
        case .settings:
            SettingsView()
                .withMenuButton { goBack() }
        case .testDebug:
            TestDebugView()
                .withMenuButton { goBack() }
        default:
            EmptyView()
        }
    }

    private func goBack() {
        withAnimation(.spring(duration: 0.3)) {
            activeMode = nil
        }
    }
}

struct MenuButtonModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                Button(action: action) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 52)
            }
    }
}

extension View {
    func withMenuButton(action: @escaping () -> Void) -> some View {
        modifier(MenuButtonModifier(action: action))
    }
}
