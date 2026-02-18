import Foundation

enum AppDebug {
    static var isDebugEnabled: Bool {
        #if DEBUG
        true
        #else
        ProcessInfo.processInfo.arguments.contains("--pulselog-debug")
        #endif
    }
}
