import SwiftUI

struct LoginContentView: View {
    let initialMode: ActiveAppMode
    @State private var vm: LoginViewModel

    init(initialMode: ActiveAppMode) {
        self.initialMode = initialMode
        self._vm = State(wrappedValue: LoginViewModel.shared)
    }

    private var accentColor: Color {
        .green
    }

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "bolt.shield.fill") {
                NavigationStack {
                    LoginDashboardView(vm: vm)
                }
            }

            Tab("Credentials", systemImage: "person.text.rectangle") {
                NavigationStack {
                    LoginCredentialsListView(vm: vm)
                        .navigationDestination(for: String.self) { credId in
                            if let cred = vm.credentials.first(where: { $0.id == credId }) {
                                LoginCredentialDetailView(credential: cred, vm: vm)
                            }
                        }
                }
            }

            Tab("Working", systemImage: "checkmark.shield.fill") {
                NavigationStack {
                    WorkingLoginsView(vm: vm)
                }
            }

            Tab("Sessions", systemImage: "rectangle.stack") {
                NavigationStack {
                    LoginSessionMonitorView(vm: vm)
                }
            }

            Tab("More", systemImage: "ellipsis.circle") {
                NavigationStack {
                    LoginMoreMenuView(vm: vm)
                }
            }
        }
        .tint(accentColor)
        .alert("Batch Complete", isPresented: $vm.showBatchResultPopup) {
            Button("OK") { vm.showBatchResultPopup = false }
        } message: {
            if let result = vm.lastBatchResult {
                Text(result.summary)
            }
        }
    }
}
