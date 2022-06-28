import Foundation

public typealias PusherUserInfoObject = [String : AnyObject]

@objcMembers
@objc open class PusherPresenceChannel: PusherChannel {
    open var members: [PusherPresenceChannelMember]
    open var onMemberAdded: ((PusherPresenceChannelMember) -> ())?
    open var onMemberRemoved: ((PusherPresenceChannelMember) -> ())?
    open var myId: String? = nil

    /**
        Initializes a new PusherPresenceChannel with a given