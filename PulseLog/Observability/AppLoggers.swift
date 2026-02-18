import Foundation
import OSLog

enum AppLoggers {
    static let networking = Logger(subsystem: "com.pulselog.network", category: "client")
    static let persistence = Logger(subsystem: "com.pulselog.persistence", category: "swiftdata")
    static let lifecycle = Logger(subsystem: "com.pulselog.lifecycle", category: "viewmodel")
    static let ui = Logger(subsystem: "com.pulselog.ui", category: "render")
    static let memory = Logger(subsystem: "com.pulselog.memory", category: "dashboard")

    static let pointsOfInterest = OSLog(subsystem: "com.pulselog.poi", category: "pointsOfInterest")
}
