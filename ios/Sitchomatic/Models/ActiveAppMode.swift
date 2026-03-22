import Foundation

nonisolated enum ActiveAppMode: String, CaseIterable, Sendable {
    case joe = "joe"
    case ignition = "ignition"
    case bpoint = "bpoint"
    case joePoint = "joePoint"
    case debugLog = "debugLog"
    case vault = "vault"
    case settings = "settings"
    case testDebug = "testDebug"
}
