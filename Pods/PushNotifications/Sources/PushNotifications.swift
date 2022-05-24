#if os(iOS)
import UIKit
import UserNotifications
#elseif os(OSX)
import Cocoa
import NotificationCenter
#endif
import Foundation

@objc public final class PushNotifications: NSObject {
    private let session = URLSession(configuration: .default)
    private let preIISOperationQueue = DispatchQueue(label: Constants.DispatchQueue.preIISOperationQueue)
    private let persistenceStorageOperationQueue = DispatchQueue(label: Constants.DispatchQueue.persistenceStorageOperationQueue)
    private let networkService: PushNotificationsNetworkable

    // The object that acts as the delegate of push notifications.
    public weak var delegate: InterestsChangedDelegate?

    //! Returns a shared singleton PushNotifications object.
    /// - Tag: shared
    @objc public static let shared = PushNotifications()

    public override init() {
        self.networkService = NetworkService(session: self.session)

        if !Device.idAlreadyPresent() {
            preIISOperationQueue.suspend()
        }
    }

    /**
     Start PushNotifications service.

     - Parameter instanceId: PushNotifications instance id.

     - Precondition: `instanceId` sh