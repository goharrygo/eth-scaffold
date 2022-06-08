import Foundation

protocol ReportEventType: Encodable {}

struct OpenEventType: ReportEventType {
    let event: String
    let publishId: String
    let deviceId: String
    let timestampSecs: UInt

    init(event: String = Constants.ReportEventType.open, publishId: String, deviceId: String, timestampSe