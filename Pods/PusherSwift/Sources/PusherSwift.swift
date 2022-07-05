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
  