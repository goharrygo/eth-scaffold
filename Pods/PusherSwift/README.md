
# PusherSwift (pusher-websocket-swift) (also works with Objective-C!)

[![Build Status](https://travis-ci.org/pusher/pusher-websocket-swift.svg?branch=master)](https://travis-ci.org/pusher/pusher-websocket-swift)
![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
[![Platform](https://img.shields.io/cocoapods/p/PusherSwift.svg?style=flat)](http://cocoadocs.org/docsets/PusherSwift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/PusherSwift.svg)](https://img.shields.io/cocoapods/v/PusherSwift.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Pusher-blue.svg?style=flat)](http://twitter.com/Pusher)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/pusher/pusher-websocket-swift/master/LICENSE.md)

Supports iOS, macOS (OS X) and tvOS! (Hopefully watchOS soon!)


## I just want to copy and paste some code to get me started

What else would you want? Head over to one of our example apps:

* For iOS with Swift, see [ViewController.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Swift/iOS%20Example%20Swift/ViewController.swift)
* For iOS with Objective-C, see [ViewController.m](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Obj-C/iOS%20Example%20Obj-C/ViewController.m)
* For macOS with Swift, see [AppDelegate.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/macOS%20Example%20Swift/macOS%20Example%20Swift/AppDelegate.swift)


## Table of Contents

* [Installation](#installation)
* [Configuration](#configuration)
* [Connection](#connection)
  * [Connection delegate](#connection-delegate)
  * [Reconnection](#reconnection)
* [Subscribing to channels](#subscribing)
  * [Public channels](#public-channels)
  * [Private channels](#private-channels)
  * [Presence channels](#presence-channels)
* [Binding to events](#binding-to-events)
  * [Globally](#global-events)
  * [Per-channel](#per-channel-events)
  * [Receiving errors](#receiving-errors)
* [Push notifications](#push-notifications)
  * [Pusher delegate](#pusher-delegate)
* [Testing](#testing)
* [Extensions](#extensions)
* [Communication](#communication)
* [Credits](#credits)
* [License](#license)


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects and is our recommended method of installing PusherSwift and its dependencies.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate PusherSwift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

pod 'PusherSwift', '~> 5.0'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update PusherSwift
$ pod install
```

Also you'll need to make sure that you've not got the version of PusherSwift locked to an old version in your `Podfile.lock` file.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PusherSwift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pusher/pusher-websocket-swift"
```

## Configuration

There are a number of configuration parameters which can be set for the Pusher client. For Swift usage they are:

- `authMethod (AuthMethod)` - the method you would like the client to use to authenticate subscription requests to channels requiring authentication (see below for more details)
- `attemptToReturnJSONObject (Bool)` - whether or not you'd like the library to try and parse your data as JSON (or not, and just return a string)
- `encrypted (Bool)` - whether or not you'd like to use encypted transport or not, default is `true`
- `autoReconnect (Bool)` - set whether or not you'd like the library to try and autoReconnect upon disconnection
- `host (PusherHost)` - set a custom value for the host you'd like to connect to, e.g. `PusherHost.host("ws-test.pusher.com")`
- `port (Int)` - set a custom value for the port that you'd like to connect to
- `activityTimeout (TimeInterval)` - after this time (in seconds) without any messages received from the server, a ping message will be sent to check if the connection is still working; the default value is supplied by the server, low values will result in unnecessary traffic.

The `authMethod` parameter must be of the type `AuthMethod`. This is an enum defined as:

```swift
public enum AuthMethod {
    case endpoint(authEndpoint: String)
    case authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case inline(secret: String)
    case authorizer(authorizer: Authorizer)
    case noMethod
}
```

- `endpoint(authEndpoint: String)` - the client will make a `POST` request to the endpoint you specify with the socket ID of the client and the channel name attempting to be subscribed to
- `authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)` - you specify an object that conforms to the `AuthRequestBuilderProtocol` (defined below), which must generate an `URLRequest` object that will be used to make the auth request
- `inline(secret: String)` - your app's secret so that authentication requests do not need to be made to your authentication endpoint and instead subscriptions can be authenticated directly inside the library (this is mainly desgined to be used for development)
- `authorizer(authorizer: Authorizer)` - you specify an object that conforms to the `Authorizer` protocol which must be able to provide the appropriate auth information
- `noMethod` - if you are only using public channels then you do not need to set an `authMethod` (this is the default value)

This is the `AuthRequestBuilderProtocol` definition:

```swift
public protocol AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest?
}
```

This is the `Authorizer` protocol definition:

```swift
public protocol Authorizer {
    func fetchAuthValue(socketID: String, channelName: String, completionHandler: (PusherAuth?) -> ())
}
```

where `PusherAuth` is defined as:

```swift
public class PusherAuth: NSObject {
    public let auth: String
    public let channelData: String?

    public init(auth: String, channelData: String? = nil) {
        self.auth = auth
        self.channelData = channelData
    }
}
```

Provided the authorization process succeeds you need to then call the supplied `completionHandler` with a `PusherAuth` object so that the subscription process can complete.

If for whatever reason your authorization process fails then you just need to call the `completionHandler` with `nil` as the only parameter.

Note that if you want to specify the cluster to which you want to connect then you use the `host` property as follows:

#### Swift
```swift
let options = PusherClientOptions(
    host: .cluster("eu")
)
```

#### Objective-C
```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/pusher/auth"];
OCPusherHost *host = [[OCPusherHost alloc] initWithCluster:@"eu"];
PusherClientOptions *options = [[PusherClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                attemptToReturnJSONObject:YES
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                encrypted:YES];
```

All of these configuration options need to be passed to a `PusherClientOptions` object, which in turn needs to be passed to the Pusher object, when instantiating it, for example:

#### Swift
```swift
let options = PusherClientOptions(
    authMethod: .endpoint(authEndpoint: "http://localhost:9292/pusher/auth")
)

let pusher = Pusher(key: "APP_KEY", options: options)
```

#### Objective-C
```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/pusher/auth"];
OCPusherHost *host = [[OCPusherHost alloc] initWithCluster:@"eu"];
PusherClientOptions *options = [[PusherClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                attemptToReturnJSONObject:YES
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                encrypted:YES];
pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY" options:options];
```

As you may have noticed, this differs slightly for Objective-C usage. The main changes are that you need to use `OCAuthMethod` and `OCPusherHost` in place of `AuthMethod` and `PusherHost`. The `OCAuthMethod` class has the following functions that you can call in your Objective-C code.

```swift
public init(authEndpoint: String)

public init(authRequestBuilder: AuthRequestBuilderProtocol)

public init(secret: String)

public init()
```

```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];
```

The case is similar for `OCPusherHost`. You have the following functions available:

```objc
public init(host: String)

public init(cluster: String)
```

```objc
[[OCPusherHost alloc] initWithCluster:@"YOUR_CLUSTER_SHORTCODE"];
```

Authenticated channel example:

#### Swift
```swift
class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/builder")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channel.name)".data(using: String.Encoding.utf8)
        request.addValue("myToken", forHTTPHeaderField: "Authorization")
        return request
    }
}

let options = PusherClientOptions(
    authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
)
let pusher = Pusher(
  key: "APP_KEY",
  options: options
)
```

#### Objective-C
```objc
@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@implementation AuthRequestBuilder

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];

    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, channelName];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    mutableRequest.HTTPBody = data;
    mutableRequest.HTTPMethod = @"POST";
    [mutableRequest addValue:@"myToken" forHTTPHeaderField:@"Authorization"];

    request = [mutableRequest copy];

    return request;
}

@end

OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthRequestBuilder:[[AuthRequestBuilder alloc] init]];
PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];
```

Where `"Authorization"` and `"myToken"` are the field and value your server is expecting in the headers of the request.

## Connection

A Websocket connection is established by providing your API key to the constructor function:

#### Swift
```swift
let pusher = Pusher(key: "APP_KEY")
pusher.connect()
```

#### Objective-C
```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
[pusher connect];
```

This returns a client object which can then be used to subscribe to channels and then calling `connect()` triggers the connection process to start.

You can also set a `userDataFetcher` on the connection object.

- `userDataFetcher (() -> PusherPresenceChannelMember)` - if you are subscribing to an authenticated channel and wish to provide a function to return user data

You set it like this:

#### Swift
```swift
let pusher = Pusher(key: "APP_KEY")

pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
    return PusherPresenceChannelMember(userId: "123", userInfo: ["twitter": "hamchapman"])
}
```

#### Objective-C
```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];

pusher.connection.userDataFetcher = ^PusherPresenceChannelMember* () {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [[PusherPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
};
```

### Connection delegate

There is a `PusherDelegate` that you can use to get notified of connection-related information. These are the functions that you can optionally implement when conforming to the `PusherDelegate` protocol:

```swift
@objc optional func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
@objc optional func subscribedToChannel(name: String)
@objc optional func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)
@objc optional func debugLog(message: String)
```

The names of the functions largely give away what their purpose is but just for completeness:

- `changedConnectionState` - use this if you want to use connection state changes to perform different actions / UI updates
- `subscribedToChannel` - use this if you want to be informed of when a channel has successfully been subscribed to, which is useful if you want to perform actions that are only relevant after a subscription has succeeded, e.g. logging out the members of a presence channel
- `failedToSubscribeToChannel` - use this if you want to be informed of a failed subscription attempt, which you could use, for exampple, to then attempt another subscription or make a call to a service you use to track errors
- `debugLog` - use this if you want to log Pusher-related events, e.g. the underlying websocket receiving a message

Setting up a delegate looks like this:

#### Swift
```swift
class ViewController: UIViewController, PusherDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let pusher = Pusher(key: "APP_KEY")
        pusher.connection.delegate = self
        // ...
    }
}
```

#### Objective-C
```objc
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.client = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];

    self.client.connection.delegate = self;
    // ...
}
```

Here are examples of setting up a class with functions for each of the optional protocol functions:

#### Swift
```swift
class DummyDelegate: PusherDelegate {
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // ...
    }

    func debugLog(message: String) {
        // ...
    }

    func subscribedToChannel(name: String) {
        // ...
    }

    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        // ...
    }
}
```

#### Objective-C
```objc
@interface DummyDelegate : NSObject <PusherDelegate>

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_
- (void)debugLogWithMessage:(NSString *)message
- (void)subscribedToChannelWithName:(NSString *)name
- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error

@end

@implementation DummyDelegate

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_ {
    // ...
}

- (void)debugLogWithMessage:(NSString *)message {
    // ...
}

- (void)subscribedToChannelWithName:(NSString *)name {
    // ...
}

- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error {
    // ...
}

@end
```

The different states that the connection can be in are (Objective-C integer enum cases in brackets):

* `connecting (0)` - the connection is about to attempt to be made
* `connected (1)` - the connection has been successfully made
* `disconnecting (2)` - the connection has been instructed to disconnect and it is just about to do so
* `disconnected (3)` - the connection has disconnected and no attempt will be made to reconnect automatically
* `reconnecting (4)` - an attempt is going to be made to try and re-establish the connection

There is a `stringValue()` function that you can call on `ConnectionState` objects in order to get a `String` representation of the state, for example `"connecting"`.


### Reconnection

There are three main ways in which a disconnection can occur:

  * The client explicitly calls disconnect and a close frame is sent over the websocket connection
  * The client experiences some form of network degradation which leads to a heartbeat (ping/pong) message being missed and thus the client disconnects
  * The Pusher server closes the websocket connection; typically this will only occur during a restart of the Pusher socket servers and an almost immediate reconnection should occur

In the case of the first type of disconnection the library will (as you'd hope) not attempt a reconnection.

The library uses [Reachability](https://github.com/ashleymills/Reachability.swift) to attempt to detect network degradation events that lead to disconnection. If this is detected then the library will attempt to reconnect (by default) with an exponential backoff, indefinitely (the maximum time between reconnect attempts is, by default, capped at 120 seconds). The value of `reconnectAttemptsMax` is a public property on the `PusherConnection` and so can be changed if you wish to set a maximum number of reconnect attempts.

If the Pusher servers close the websocket, or if a disconnection happens due to nevtwork events that aren't covered by Reachability, then the library will still attempt to reconnect as described above.

All of this is the case if you have the client option of `autoReconnect` set as `true`, which it is by default. If the reconnection strategies are not suitable for your use case then you can set `autoReconnect` to `false` and implement your own reconnection strategy based on the connection state changes.

There are a couple of properties on the connection (`PusherConnection`) that you can set that affect how the reconnection behaviour works. These are:

* `public var reconnectAttemptsMax: Int? = 6` - if you set this to `nil` then there is no maximum number of reconnect attempts and so attempts will continue to be made with an exponential backoff (based on number of attempts), otherwise only as many attempts as this property's value will be made before the connection's state moves to `.disconnected`
* `public var maxReconnectGapInSeconds: Double? = nil` - if you want to set a maximum length of time (in seconds) between reconnect attempts then set this property appropriately

Note that the number of reconnect attempts gets reset to 0 as soon as a successful connection is made.

## Subscribing

### Public channels

The default method for subscribing to a channel involves invoking the `subscribe` method of your client object:

#### Swift
```swift
let myChannel = pusher.subscribe("my-channel")
```

#### Objective-C
```objc
PusherChannel *myChannel = [pusher subscribeWithChannelName:@"my-channel"];
```

This returns PusherChannel object, which events can be bound to.

### Private channels

Private channels are created in exactly the same way as public channels, except that they reside in the 'private-' namespace. This means prefixing the channel name:

#### Swift
```swift
let myPrivateChannel = pusher.subscribe("private-my-channel")
```

#### Objective-C
```objc
PusherChannel *myPrivateChannel = [pusher subscribeWithChannelName:@"private-my-channel"];
```

Subscribing to private channels involves the client being authenticated. See the [Configuration](#configuration) section for the authenticated channel example for more information.

### Presence channels

Presence channels are channels whose names are prefixed by `presence-`.

The recommended way of subscribing to a presence channel is to use the `subscribeToPresenceChannel` function, as opposed to the standard `subscribe` function. Using the `subscribeToPresenceChannel` function means that you get a `PusherPresenceChannel` object returned, as opposed to a standard `PusherChannel`. This `PusherPresenceChannel` object has some extra, presence-channel-specific functions availalbe to it, such as `members`, `me`, and `findMember`.

#### Swift
```swift
let myPresenceChannel = pusher.subscribeToPresenceChannel(channelName: "presence-my-channel")
```

#### Objective-C
```objc
PusherPresenceChannel *myPresenceChannel = [pusher subscribeToPresenceChannelWithChannelName:@"presence-my-channel"];
```

As alluded to, you can still subscribe to presence channels using the `subscribe` method, but the channel object you get back won't have access to the presence-channel-specific functions, unless you choose to cast the channel object to a `PusherPresenceChannel`.

#### Swift
```swift
let myPresenceChannel = pusher.subscribe("presence-my-channel")
```

#### Objective-C
```objc
PusherChannel *myPresenceChannel = [pusher subscribeWithChannelName:@"presence-my-channel"];
```

You can also provide functions that will be called when members are either added to or removed from the channel. These are available as parameters to both `subscribe` and `subscribeToPresenceChannel`.

#### Swift
```swift
let onMemberChange = { (member: PusherPresenceChannelMember) in
    print(member)
}

let chan = pusher.subscribeToPresenceChannel("presence-channel", onMemberAdded: onMemberChange, onMemberRemoved: onMemberChange)
```

#### Objective-C
```objc
void (^onMemberChange)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
    NSLog(@"%@", member);
};

PusherChannel *myPresenceChannel = [pusher subscribeWithChannelName:@"presence-my-channel" onMemberAdded:onMemberChange onMemberRemoved:onMemberChange];
```

**Note**: The `members` and `myId` properties of `PusherPresenceChannel` objects (and functions that get the value of these properties) will only be set once subscription to the channel has succeeded.

The easiest way to find out when a channel has been successfully susbcribed to is to bind to the event named `pusher:subscription_succeeded` on the channel you're interested in. It would look something like this:

#### Swift
```swift
let pusher = Pusher(key: "YOUR_APP_KEY")

let chan = pusher.subscribeToPresenceChannel("presence-channel")

chan.bind(eventName: "pusher:subscription_succeeded", callback: { data in
    print("Subscribed!")
    print("I can now access myId: \(chan.myId)")
    print("And here are the channel members: \(chan.members)")
})
```

#### Objective-C
```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherPresenceChannel *chan = [pusher subscribeToPresenceChannelWithChannelName:@"presence-channel"];

[chan bindWithEventName:@"pusher:subscription_succeeded" callback: ^void (NSDictionary *data) {
    NSLog(@"Subscribed!");
    NSLog(@"I can now access myId: %@", chan.myId);
    NSLog(@"And here are my channel members: %@", chan.members);
}];
```

You can also be notified of a successfull subscription by using the `subscriptionDidSucceed` delegate method that is part of the `PusherDelegate` protocol.

Here is an example of using the delegate:

#### Swift
```swift
class DummyDelegate: PusherDelegate {
    func subscribedToChannel(name: String) {
        if channelName == "presence-channel" {
            if let presChan = pusher.connection.channels.findPresence(channelName) {
                // in here you can now have access to the channel's members and myId properties
                print(presChan.members)
                print(presChan.myId)
            }
        }
    }
}

let pusher = Pusher(key: "YOUR_APP_KEY")
pusher.connection.delegate = DummyDelegate()
let chan = pusher.subscribeToPresenceChannel("presence-channel")
```

#### Objective-C
```objc
@implementation DummyDelegate

- (void)subscribedToChannelWithName:(NSString *)name {
    if ([channelName isEqual: @"presence-channel"]) {
        PusherPresenceChannel *presChan = [self.client.connection.channels findPresenceWithName:@"presence-channel"];
        NSLog(@"%@", [presChan members]);
        NSLog(@"%@", [presChan myId]);
    }
}

@implementation ViewController

- (void)viewDidLoad {
    // ...

    Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
    pusher.connection.delegate = [[DummyDelegate alloc] init];
    PusherChannel *chan = [pusher subscribeToPresenceChannelWithChannelName:@"presence-channel"];