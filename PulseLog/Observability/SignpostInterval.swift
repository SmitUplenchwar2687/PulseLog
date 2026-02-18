import Foundation
import os.signpost

struct SignpostInterval {
    private let log: OSLog
    private let name: StaticString
    private let id: OSSignpostID

    init(log: OSLog = AppLoggers.pointsOfInterest, name: StaticString, message: String = "") {
        self.log = log
        self.name = name
        self.id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id, "%{public}s", message)
    }

    func end(message: String = "") {
        os_signpost(.end, log: log, name: name, signpostID: id, "%{public}s", message)
    }
}
