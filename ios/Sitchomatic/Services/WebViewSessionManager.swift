import Foundation
import WebKit

@Observable
final class WebViewSessionManager {
    private var activeSessions: [UUID: WKWebView] = [:]
    private var navigationDelegates: [UUID: WebViewNavigationDelegate] = [:]
    private let maxConcurrent: Int = 20
    private static let sharedProcessPool = WKProcessPool()

    func createSession() -> (UUID, WKWebView) {
        cleanupExcessSessions()

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.suppressesIncrementalRendering = true
        config.processPool = Self.sharedProcessPool

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 812), configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

        let sessionId = UUID()
        let delegate = WebViewNavigationDelegate()
        webView.navigationDelegate = delegate
        navigationDelegates[sessionId] = delegate
        activeSessions[sessionId] = webView
        return (sessionId, webView)
    }

    func waitForPageLoad(_ sessionId: UUID, timeout: TimeInterval = 30) async -> Bool {
        guard let delegate = navigationDelegates[sessionId] else { return false }
        return await delegate.waitForLoad(timeout: timeout)
    }

    func getSession(_ id: UUID) -> WKWebView? {
        activeSessions[id]
    }

    func destroySession(_ id: UUID) {
        navigationDelegates.removeValue(forKey: id)
        if let webView = activeSessions.removeValue(forKey: id) {
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.loadHTMLString("", baseURL: nil)
            webView.configuration.websiteDataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: .distantPast
            ) {}
        }
    }

    func destroyAllSessions() {
        let ids = Array(activeSessions.keys)
        for id in ids {
            destroySession(id)
        }
    }

    var activeCount: Int {
        activeSessions.count
    }

    func handleMemoryPressure() {
        let excessCount = activeSessions.count - 4
        guard excessCount > 0 else { return }
        let toRemove = Array(activeSessions.keys.prefix(excessCount))
        for id in toRemove {
            destroySession(id)
        }
    }

    private func cleanupExcessSessions() {
        while activeSessions.count >= maxConcurrent {
            if let oldest = activeSessions.keys.first {
                destroySession(oldest)
            }
        }
    }
}

final class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    private var loadContinuation: CheckedContinuation<Bool, Never>?
    private var isLoaded = false
    private var didFail = false

    func waitForLoad(timeout: TimeInterval) async -> Bool {
        if isLoaded { return true }
        if didFail { return false }

        return await withCheckedContinuation { continuation in
            self.loadContinuation = continuation

            Task {
                try? await Task.sleep(for: .seconds(timeout))
                if let c = self.loadContinuation {
                    self.loadContinuation = nil
                    c.resume(returning: self.isLoaded)
                }
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.isLoaded = true
            if let c = self.loadContinuation {
                self.loadContinuation = nil
                c.resume(returning: true)
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.didFail = true
            if let c = self.loadContinuation {
                self.loadContinuation = nil
                c.resume(returning: false)
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.didFail = true
            if let c = self.loadContinuation {
                self.loadContinuation = nil
                c.resume(returning: false)
            }
        }
    }
}
