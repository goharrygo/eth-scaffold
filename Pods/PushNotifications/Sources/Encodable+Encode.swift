import Foundation

extension Encodable {
    func encode() throws -> Data {
        return try JSONEncod