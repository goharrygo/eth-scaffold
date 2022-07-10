import Foundation
import Starscream

let PROTOCOL = 7
let VERSION = "6.1.0"
let CLIENT_NAME = "pusher-websocket-swift"

@objcMembers
@objc open class Pusher: NSObject {
    open let connection: PusherConnection
    open weak var delegate: PusherDelegate? = nil {
        willSet {
            self.connection.delegate = newValue
#if os(iOS) || os(OSX)
            self.nativePusher.delegate = newValue
#endif
        }
    }
    private let key: String

#if os(iOS) || os(OSX)
    public let nativePusher: NativePusher

    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:          The Pusher app key
        - parameter options:      An optional collection of options
        - parameter nativePusher: A NativePusher instance for the app that the provided
                                  key belongs to

        - returns: A new Pusher client instance
    */
    public init(key: String, options: PusherClientOptions = PusherClientOptions(), nativePusher: NativePusher? = nil) {
        self.key = key
        let urlString = constructUrl(key: key, options: options)
        let ws = WebSocket(url: URL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: options)
        connection.createGlobalChannel()
        self.nativePusher = nativePusher ?? NativePusher()
        self.nativePusher.setPusherAppKey(pusherAppKey: key)
    }
#endif

#if os(tvOS)
    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:          The Pusher app key
        - parameter options:      An optional collection of options

        - returns: A new Pusher client instance
    */
    public init(key: String, options: PusherClientOptions = PusherClientOptions()) {
        self.key = key
        let urlString = constructUrl(key: key, options: options)
        let ws = WebSocket(url: URL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: ur