import Foundation

struct Metadata: Encodable {
    let sdkVersion: String?
    let iosVersion: String?
    let macosVersion: String?
}

extension Metadata: PropertyListReadable {
    func propertyListRepresentation() -> [String: Any] {
        return ["sdkVersion": self.sdkVersion ?? "", "iosVersion": self.iosVersion ?? "", "macosVersion": self.macosVersion ?? ""]
    }

    init(propertyListRepresentation: [String: Any]) {
        self.sdkVersion = propertyListRepresentation["sdkVersion"]  as? String
        self.iosVersion = 