
import Foundation

protocol InterestPersistable {
    @discardableResult func persist(interest: String) -> Bool
    @discardableResult func persist(interests: [String]) -> Bool
    @discardableResult func remove(interest: String) -> Bool
    func removeAll()
    func getSubscriptions() -> [String]?

    func persistServerConfirmedInterestsHash(_ hash: String)
    func getServerConfirmedInterestsHash() -> String
}