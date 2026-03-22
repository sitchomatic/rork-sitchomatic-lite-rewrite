# Sitchomatic v3.0 — 14+ Concurrent Sessions with JoePoint Mode

## What's been implemented

All features from v2.0 plus major upgrades for 14+ concurrent session stability, JoePoint combined mode, intelligent submit retry, configurable delays, and background persistence.

---

### ✅ Completed — v2.0 Foundation

**1. Real concurrent login batches** ✅
- `withTaskGroup` + `AsyncSemaphore` for true parallel execution
- Each session gets isolated non-persistent WebView, destroyed after use

**2. Real concurrent BPoint batches** ✅
- Same concurrent pattern, each attempt with its own WebView session

**3. Test & Debug optimizer** ✅
- Real login attempts via `SimpleHardcodedLoginService`
- Per-site ViewModel selection, actual success/fail/disabled counts

**4. Memory pressure handling** ✅
- Both LoginViewModels, BPointViewModel, DebugLogger handle memory warnings
- Trims old attempts, excess sessions, log entries

**5. Data isolation (Joe/Ignition)** ✅
- Site-specific credential storage keys
- Per-site settings persistence

**6. Swift concurrency annotations** ✅
- All data types `nonisolated` + `Sendable`, `AsyncSemaphore` as actor

---

### ✅ Completed — v3.0 High Concurrency Upgrade

**7. 14+ concurrent sessions** ✅
- `WebViewSessionManager` max raised to 20, each with isolated `WKProcessPool`
- Concurrency sliders raised to 1–14 across Login, BPoint, and JoePoint
- Timeout raised to 45s for reliability under load

**8. Intelligent submit retry (login flow)** ✅
- Click submit → wait for button color to restore to original → wait 1s → resubmit
- Repeats exactly 4 times with color-based intelligent wait (max 5s per cycle)
- After each submit: checks for "has been disabled" (perm) vs "temporarily disabled" (temp)
- Assigns to respective categories: `.permDisabled` or `.tempDisabled`

**9. Configurable Post Page Settle Delay** ✅
- `postPageSettleDelayMs` property on `LoginViewModel` (default 2000ms, 0–10000ms)
- Slider control in Login Settings, Dashboard, More Menu, and Test & Debug
- Persisted per-site via `PersistenceService`
- Replaces old hardcoded 2-second wait

**10. JoePoint Mode (combined Login + BPoint)** ✅
- New `JoePointViewModel` runs login + BPoint batches simultaneously
- Configurable split: login concurrency + BPoint concurrency (both 1–14)
- Shared `BackgroundTaskService` for no-sleep and background persistence
- Dedicated `JoePointDashboardView` with full config and live results
- Added to `MainMenuView` and `ContentView` navigation

**11. Background & No-Sleep Support** ✅
- `BackgroundTaskService` tracks active runners
- `UIApplication.shared.isIdleTimerDisabled = true` while any test runs
- `UIBackgroundTaskIdentifier` for background execution
- Auto-resets when all runners finish
- Runner count shown in Main Menu and Settings

**12. Perm Disabled Category** ✅
- New `.permDisabled` credential status with distinct detection
- Keywords: "has been disabled", "permanently disabled", "account closed", "blacklisted"
- Separate from temp disabled: "temporarily disabled", "too many attempts", "suspended"
- New `PermDisabledView` in More Menu for viewing perm-disabled accounts
- Stats card on Dashboard showing perm disabled count

**13. Speed Demon & Slow Debug one-tap buttons** ✅
- In More Menu under Automation Tools section
- Quick preset buttons in Test & Debug (Speed Demon, Slow Debug, Max Concurrency, Balanced)
- Speed Demon preset sets concurrency to 14, settle to 500ms
- Slow Debug preset sets concurrency to 2, settle to 3000ms

**14. Test & Debug Optimizer upgrades** ✅
- Settle delay slider added to test config
- Concurrency raised to 1–14
- Session results show concurrency and settle delay used
- 4 quick presets: Speed Demon, Slow Debug, Max Concurrency, Balanced

**15. Updated Settings** ✅
- Per-site Post Page Settle Delay sliders
- Per-site concurrency up to 14
- Background service status indicator
- Version bumped to 3.0.0
