import Foundation

// https://stackoverflow.com/a/40031342
extension Data {
    func hexadecimalRepresentation() -> String {
        return map { String(format: "%02.2hhx", $0) }.joined()
    }
}

// https://stackoverflow.com/a/26502285
extension String {
    func toData() -> Data? {
        var data = Data(capacity: self.count / 2)

        guard let regex = try? NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .cas