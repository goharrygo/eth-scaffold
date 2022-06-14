import Foundation

@objcMembers
@objc open class PusherChannels: NSObject {
    open var channels = [String: PusherChannel]()

    /**
        Create a new PusherChannel, which is returned, and add it to the PusherChannels list
        of channels

        - parameter name:            The name of the channel to create
        - parameter connection:      The connection associated with the channel being created
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with infor