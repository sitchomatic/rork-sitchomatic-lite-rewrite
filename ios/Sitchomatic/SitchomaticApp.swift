import SwiftUI

@main
struct SitchomaticApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    LoginViewModel.joe.handleMemoryPressure()
                    LoginViewModel.ignition.handleMemoryPressure()
                    BPointViewModel.shared.handleMemoryPressure()
                    DebugLogger.shared.handleMemoryPressure()
                }
        }
    }
}
