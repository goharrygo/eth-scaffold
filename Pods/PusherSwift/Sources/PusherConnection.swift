
import Foundation
import Reachability
import Starscream
import CryptoSwift

public typealias PusherEventJSON = [String: AnyObject]

@objcMembers
@objc open class PusherConnection: NSObject {
    open let url: String
    open let key: String
    open var options: PusherClientOptions
    open var globalChannel: GlobalChannel!
    open var socketId: String?
    open var connectionState = ConnectionState.disconnected
    open var channels = PusherChannels()
    open var socket: WebSocket!
    open var URLSession: Foundation.URLSession
    open var userDataFetcher: (() -> PusherPresenceChannelMember)?
    open var reconnectAttemptsMax: Int? = nil
    open var reconnectAttempts: Int = 0
    open var maxReconnectGapInSeconds: Double? = 120
    open weak var delegate: PusherDelegate?
    open var pongResponseTimeoutInterval: TimeInterval = 30
    open var activityTimeoutInterval: TimeInterval
    var reconnectTimer: Timer? = nil
    var pongResponseTimeoutTimer: Timer? = nil
    var activityTimeoutTimer: Timer? = nil
    var intentionalDisconnect: Bool = false

    var socketConnected: Bool = false {
        didSet {
            setConnectionStateToConnectedAndAttemptSubscriptions()
        }
    }
    var connectionEstablishedMessageReceived: Bool = false {
        didSet {
            setConnectionStateToConnectedAndAttemptSubscriptions()
        }
    }

    open lazy var reachability: Reachability? = {
        let reachability = Reachability.init()
        reachability?.whenReachable = { [weak self] reachability in
            guard self != nil else {
                print("Your Pusher instance has probably become deallocated. See https://github.com/pusher/pusher-websocket-swift/issues/109 for more information")
                return
            }

            self!.delegate?.debugLog?(message: "[PUSHER DEBUG] Network reachable")

            switch self!.connectionState {
            case .disconnecting, .connecting, .reconnecting:
                // If in one of these states then part of the connection, reconnection, or explicit
                // disconnection process is underway, so do nothing
                return
            case .disconnected:
                // If already disconnected then reset connection and try to reconnect, provided the
                // state isn't disconnected because of an intentional disconnection
                if !self!.intentionalDisconnect { self!.resetConnectionAndAttemptReconnect() }
                return
            case .connected:
                // If already connected then we assume that there was a missed network event that
                // led to a bad connection so we move to the disconnected state and then attempt
                // reconnection
                self!.delegate?.debugLog?(
                    message: "[PUSHER DEBUG] Connection state is \(self!.connectionState.stringValue()) but received network reachability change so going to call attemptReconnect"
                )
                self!.resetConnectionAndAttemptReconnect()
                return
            }
        }
        reachability?.whenUnreachable = { [weak self] reachability in
            guard self != nil else {
                print("Your Pusher instance has probably become deallocated. See https://github.com/pusher/pusher-websocket-swift/issues/109 for more information")
                return
            }

            self!.delegate?.debugLog?(message: "[PUSHER DEBUG] Network unreachable")
            self!.resetConnectionAndAttemptReconnect()
        }
        return reachability
    }()

    /**
        Initializes a new PusherConnection with an app key, websocket, URL, options and URLSession

        - parameter key:        The Pusher app key
        - parameter socket:     The websocket object
        - parameter url:        The URL the connection is made to
        - parameter options:    A PusherClientOptions instance containing all of the user-speficied
                                client options
        - parameter URLSession: An NSURLSession instance for the connection to use for making
                                authentication requests

        - returns: A new PusherConnection instance
    */
    public init(
        key: String,
        socket: WebSocket,
        url: String,
        options: PusherClientOptions,
        URLSession: Foundation.URLSession = Foundation.URLSession.shared
    ) {
        self.url = url
        self.key = key
        self.options = options
        self.URLSession = URLSession
        self.socket = socket
        self.activityTimeoutInterval = options.activityTimeout ?? 60
        super.init()
        self.socket.delegate = self
        self.socket.pongDelegate = self
    }

    deinit {
        self.reconnectTimer?.invalidate()
        self.activityTimeoutTimer?.invalidate()
        self.pongResponseTimeoutTimer?.invalidate()
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName:     The name of the channel
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func subscribe(
        channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherChannel {
            let newChannel = channels.add(
                name: channelName,
                connection: self,
                auth: auth,
                onMemberAdded: onMemberAdded,
                onMemberRemoved: onMemberRemoved
            )

            guard self.connectionState == .connected else { return newChannel }

            if !self.authorize(newChannel, auth: auth) {
                print("Unable to subscribe to channel: \(newChannel.name)")
            }

            return newChannel
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName:     The name of the channel
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
        member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
        member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func subscribeToPresenceChannel(
        channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherPresenceChannel {
        let newChannel = channels.addPresence(
            channelName: channelName,
            connection: self,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )

        guard self.connectionState == .connected else { return newChannel }

        if !self.authorize(newChannel, auth: auth) {
            print("Unable to subscribe to channel: \(newChannel.name)")
        }

        return newChannel
    }

    /**
        Unsubscribes from a PusherChannel with a given name

        - parameter channelName: The name of the channel
    */
    internal func unsubscribe(channelName: String) {
        if let chan = self.channels.find(name: channelName), chan.subscribed {
            self.sendEvent(event: "pusher:unsubscribe",
                data: [
                    "channel": channelName
                ] as [String : Any]
            )
            self.channels.remove(name: channelName)
        }
    }
    
    /**
        Unsubscribes from all PusherChannels
    */
    internal func unsubscribeAll() {
        for (_, channel) in channels.channels {
            unsubscribe(channelName: channel.name)
        }
    }

    /**
        Either writes a string directly to the websocket with the given event name
        and data, or calls a client event to be sent if the event is prefixed with
        "client"

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    open func sendEvent(event: String, data: Any, channel: PusherChannel? = nil) {
        if event.components(separatedBy: "-")[0] == "client" {
            sendClientEvent(event: event, data: data, channel: channel)
        } else {
            let dataString = JSONStringify(["event": event, "data": data])
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] sendEvent \(dataString)")
            self.socket.write(string: dataString)
        }
    }

    /**
        Sends a client event with the given event, data, and channel name

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    fileprivate func sendClientEvent(event: String, data: Any, channel: PusherChannel?) {
        if let channel = channel {
            if channel.type == .presence || channel.type == .private {
                let dataString = JSONStringify(["event": event, "data": data, "channel": channel.name] as [String : Any])
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] sendClientEvent \(dataString)")
                self.socket.write(string: dataString)
            } else {
                print("You must be subscribed to a private or presence channel to send client events")
            }
        }
    }

    /**
        JSON stringifies an object

        - parameter value: The value to be JSON stringified

        - returns: A JSON-stringified version of the value
    */
    fileprivate func JSONStringify(_ value: Any) -> String {
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let string = String(data: data, encoding: .utf8)
                if string != nil {
                    return string!
                }
            } catch _ {
            }
        }
        return ""
    }

    /**
        Disconnects the websocket
    */
    open func disconnect() {
        if self.connectionState == .connected {
            intentionalDisconnect = true
            self.reachability?.stopNotifier()
            updateConnectionState(to: .disconnecting)
            self.socket.disconnect()
        }
    }

    /**
        Establish a websocket connection
    */
    @objc open func connect() {
        // reset the intentional disconnect state
        intentionalDisconnect = false

        if self.connectionState == .connected {
            return
        } else {
            updateConnectionState(to: .connecting)
            self.socket.connect()
            if self.options.autoReconnect {
                // can call this multiple times and only one notifier will be started
                _ = try? reachability?.startNotifier()
            }
        }
    }

    /**
        Instantiate a new GloblalChannel instance for the connection
    */
    internal func createGlobalChannel() {
        self.globalChannel = GlobalChannel(connection: self)
    }

    /**
        Add callback to the connection's global channel

        - parameter callback: The callback to be stored

        - returns: A callbackId that can be used to remove the callback from the connection
    */
    internal func addCallbackToGlobalChannel(_ callback: @escaping (Any?) -> Void) -> String {
        return globalChannel.bind(callback)
    }

    /**
        Remove the callback with id of callbackId from the connection's global channel

        - parameter callbackId: The unique string representing the callback to be removed
    */
    internal func removeCallbackFromGlobalChannel(callbackId: String) {
        globalChannel.unbind(callbackId: callbackId)
    }

    /**
        Remove all callbacks from the connection's global channel
    */
    internal func removeAllCallbacksFromGlobalChannel() {
        globalChannel.unbindAll()
    }

    /**
        Set the connection state and call the stateChangeDelegate, if set

        - parameter newState: The new ConnectionState value
    */
    internal func updateConnectionState(to newState: ConnectionState) {
        let oldState = self.connectionState
        self.connectionState = newState
        self.delegate?.changedConnectionState?(from: oldState, to: newState)
    }

    /**
        Update connection state and attempt subscriptions to unsubscribed channels
    */
    fileprivate func setConnectionStateToConnectedAndAttemptSubscriptions() {
        if self.connectionEstablishedMessageReceived &&
           self.socketConnected &&
           self.connectionState != .connected
        {
            updateConnectionState(to: .connected)
            attemptSubscriptionsToUnsubscribedChannels()
        }
    }

    /**
        Set the connection state to disconnected, mark channels as unsubscribed,
        reset connection-related state to initial state, and initiate reconnect
        process
    */
    fileprivate func resetConnectionAndAttemptReconnect() {
        if connectionState != .disconnected {
            updateConnectionState(to: .disconnected)
        }

        for (_, channel) in self.channels.channels {
            channel.subscribed = false
        }

        cleanUpActivityAndPongResponseTimeoutTimers()

        socketConnected = false
        connectionEstablishedMessageReceived = false
        socketId = nil

        attemptReconnect()
    }

    /**
        Reset the activity timeout timer
    */
    func resetActivityTimeoutTimer() {
        cleanUpActivityAndPongResponseTimeoutTimers()
        establishActivityTimeoutTimer()
    }

    /**
        Clean up the activity timeout and pong response timers
    */
    func cleanUpActivityAndPongResponseTimeoutTimers() {
        activityTimeoutTimer?.invalidate()
        activityTimeoutTimer = nil
        pongResponseTimeoutTimer?.invalidate()
        pongResponseTimeoutTimer = nil
    }

    /**
        Schedule a timer to be fired if no activity occurs over the socket within
        the activityTimeoutInterval
    */
    fileprivate func establishActivityTimeoutTimer() {
        self.activityTimeoutTimer = Timer.scheduledTimer(
            timeInterval: self.activityTimeoutInterval,
            target: self,
            selector: #selector(self.sendPing),
            userInfo: nil,
            repeats: false
        )
    }

    /**
        Send a ping to the server
    */
    @objc fileprivate func sendPing() {