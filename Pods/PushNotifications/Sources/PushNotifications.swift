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

     - Precondition: `instanceId` should not be nil.
     */
    /// - Tag: start
    @objc public func start(instanceId: String) {
        // Detect from where the function is being called
        let wasCalledFromCorrectLocation = Thread.callStackSymbols.contains { stack in
            return stack.contains("didFinishLaunchingWith") || stack.contains("applicationDidFinishLaunching")
        }
        if !wasCalledFromCorrectLocation {
            print("[Push Notifications] - Warning: You should call `pushNotifications.start` from the `AppDelegate.didFinishLaunchingWith`")
        }

        do {
            try Instance.persist(instanceId)
        } catch PusherAlreadyRegisteredError.instanceId(let errorMessage) {
            print("[Push Notifications] - \(errorMessage)")
        } catch {
            print("[Push Notifications] - Unexpected error: \(error).")
        }

        self.syncMetadata()
        self.syncInterests()
    }

    /**
     Register to receive remote notifications via Apple Push Notification service.

     Convenience method is using `.alert`, `.sound`, and `.badge` as default authorization options.

     - SeeAlso:  `registerForRemoteNotifications(options:)`
     */
    /// - Tag: register
    @objc public func registerForRemoteNotifications() {
        self.registerForPushNotifications(options: [.alert, .sound, .badge])
    }
    #if os(iOS)
    /**
     Register to receive remote notifications via Apple Push Notification service.

     - Parameter options: The authorization options your app is requesting. You may combine the available constants to request authorization for multiple items. Request only the authorization options that you plan to use. For a list of possible values, see [UNAuthorizationOptions](https://developer.apple.com/documentation/usernotifications/unauthorizationoptions).
     */
    /// - Tag: registerOptions
    @objc public func registerForRemoteNotifications(options: UNAuthorizationOptions) {
        self.registerForPushNotifications(options: options)
    }
    #elseif os(OSX)
    /**
     Register to receive remote notifications via Apple Push Notification service.

     - Parameter options: A bit mask specifying the types of notifications the app accepts. See [NSApplication.RemoteNotificationType](https://developer.apple.com/documentation/appkit/nsapplication.remotenotificationtype) for valid bit-mask values.
     */
    @objc public func registerForRemoteNotifications(options: NSApplication.RemoteNotificationType) {
        self.registerForPushNotifications(options: options)
    }
    #endif

    /**
     Register device token with PushNotifications service.

     - Parameter deviceToken: A token that identifies the device to APNs.
     - Parameter completion: The block to execute when the register device token operation is complete.

     - Precondition: `deviceToken` should not be nil.
     */
    /// - Tag: registerDeviceToken
    @objc public func registerDeviceToken(_ deviceToken: Data, completion: @escaping () -> Void = {}) {
        guard
            let instanceId = Instance.getInstanceId(),
            let url = URL(string: "https://\(instanceId).pushnotifications.pusher.com/device_api/v1/instances/\(instanceId)/devices/apns")
        else {
            print("[Push Notifications] - Something went wrong. Please check your instance id: \(String(describing: Instance.getInstanceId()))")
            return
        }

        if Device.idAlreadyPresent() {
            // If we have the device id that means that the token has already been registered.
            // Therefore we don't need to call `networkService.register` again.
            print("[Push Notifications] - Warning: Avoid multiple calls of `registerDeviceToken`")
            return
        }

        networkService.register(url: url, deviceToken: deviceToken, instanceId: instanceId) { [weak self] (device) in
            guard
                let device = device,
                let strongSelf = self
            else {
                return
            }

            strongSelf.persistenceStorageOperationQueue.async {
                if Device.idAlreadyPresent() {
                    print("[Push Notifications] - Warning: Avoid multiple calls of `registerDeviceToken`")
                } else {
                    Device.persist(device.id)

                    let initialInterestSet = device.initialInterestSet ?? []
                    let persistenceService: InterestPersistable = PersistenceService(service: UserDefaults(suiteName: "PushNotifications")!)
                    if initialInterestSet.count > 0 {
                        persistenceService.persist(interests: initialInterestSet)
                    }

                    strongSelf.preIISOperationQueue.async {
                        let interests = persistenceService.getSubscriptions() ?? []
                        if !initialInterestSet.containsSameElements(as: interests) {
                            strongSelf.syncInterests()
                        }

                        completion()
                    }

                    strongSelf.preIISOperationQueue.resume()
                }
            }
        }
    }

    /**
     Subscribe to an interest.

     - Parameter interest: Interest that you want to subscribe to.
     - Parameter completion: The block to execute when subscription to the interest is complete.

     - Precondition: `interest` should not be nil.

     - Throws: An error of type `InvalidInterestError`
     */
    /// - Tag: subscribe
    @objc public func subscribe(interest: String, completion: @escaping () -> Void = {}) throws {
        guard self.validateInterestName(interest) else {
            throw InvalidInterestError.invalidName(interest)
        }

        self.persistenceStorageOperationQueue.async {
            let persistenceService: InterestPersistable = PersistenceService(service: UserDefaults(suiteName: Constants.UserDefaults.suiteName)!)

            let interestAdded = persistenceService.persist(interest: interest)

            if Device.idAlreadyPresent() {
                if interestAdded {
                    guard
                        let deviceId = Device.getDeviceId(),
                        let instanceId = Instance.getInstanceId(),
                        let url = URL(string: "https://\(instanceId).pushnotifications.pusher.com/device_api/v1/instances/\(instanceId)/devices/apns/\(deviceId)/interests/\(interest)")
                    else {
                        return
                    }

                    let networkService: PushNotificationsNetworkable = NetworkService(session: self.session)
                    networkService.subscribe(url: url, completion: { _ in
                        completion()
                    })
                }
            } else {
                self.preIISOperationQueue.async {
                    persistenceService.persist(interest: interest)
                    completion()
                }
            }

            if interestAdded {
                self.interestsSetDidChange()
            }
        }
    }

    /**
     Set subscriptions.

     - Parameter interests: Interests that you want to subscribe to.
     - Parameter completion: The block to execute when subscription to interests is complete.

     - Precondition: `interests` should not be nil.

     - Throws: An error of type `MultipleInvalidInterestsError`
     */
    /// - Tag: setSubscriptions
    @objc public func setSubscriptions(interests: [String], completion: @escaping () -> Void = {}) throws {
        if let invalidInterests = self.validateInterestNames(interests), invalidInterests.count > 0 {
            throw MultipleInvalidInterestsError.invalidNames(invalidInterests)
        }

        self.persistenceStorageOperationQueue.async {
            let persistenceService: InterestPersistable = PersistenceService(service: UserDefaults(suiteName: Constants.UserDefaults.suiteName)!)

            let interestsChanged = persistenceService.persist(interests: interests)

            if Device.idAlreadyPresent() {
                if interestsChanged {
                    guard
                        let deviceId = Device.getDeviceId(),
                        let instanceId = Instance.getInstanceId(),
                        let url = URL(string: "https://\(instanceId).pushnotifications.pusher.com/device_api/v1/instances/\(instanceId)/devices/apns/\(deviceId)/interests")
                    else {
                        return
                    }

                    let networkService: PushNotificationsNetworkable = NetworkService(session: self.session)
                    networkService.setSubscriptions(url: url, interests: interests, completion: { _ in
                        completion()
                    })
                }
            } else {
                self.preIISOperationQueue.async {
                    persistenceService.persist(interests: interests)
                    completion()
                }
            }

            if interestsChanged {
                self.interestsSetDidChange()
            }
        }
 