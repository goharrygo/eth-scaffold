import Foundation

public typealias PusherUserInfoObject = [String : AnyObject]

@objcMembers
@objc open class PusherPresenceChannel: PusherChannel {
    open var members: [PusherPresenceChannelMember]
    open var onMemberAdded: ((PusherPresenceChannelMember) -> ())?
    open var onMemberRemoved: ((PusherPresenceChannelMember) -> ())?
    open var myId: String? = nil

    /**
        Initializes a new PusherPresenceChannel with a given name, conenction, and optional
        member added and member removed handler functions

        - parameter name:            The name of the channel
        - parameter connection:      The connection that this channel is relevant to
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherPresenceChannel instance
    */
    init(
        name: String,
        connection: PusherConnection,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
  