import Foundation

@objcMembers
@objc open class PusherChannels: NSObject {
    open var channels = [String: PusherChannel]()

    /**
        Create a new PusherChannel, which is returned, and add it to the PusherChannels list
        of channels

        - parameter name:            The name of the channel to create
        - parameter connection