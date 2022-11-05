![starscream](https://raw.githubusercontent.com/daltoniam/starscream/assets/starscream.jpg)

Starscream is a conforming WebSocket ([RFC 6455](http://tools.ietf.org/html/rfc6455)) client library in Swift.

Its Objective-C counterpart can be found here: [Jetfire](https://github.com/acmacalister/jetfire)

## Features

- Conforms to all of the base [Autobahn test suite](http://autobahn.ws/testsuite/).
- Nonblocking. Everything happens in the background, thanks to GCD.
- TLS/WSS support.
- Compression Extensions support ([RFC 7692](https://tools.ietf.org/html/rfc7692))
- Simple concise codebase at just a few hundred LOC.

## Example

First thing is to import the framework. See the Installation instructions on how to add the framework to your project.

```swift
import Starscream
```

Once imported, you can open a connection to your WebSocket server. Note that `socket` is probably best as a property, so it doesn't get deallocated right after being setup.

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!)
socket.delegate = self
socket.connect()
```

After you are connected, there are some delegate methods that we need to implement.

### websocketDidConnect

websocketDidConnect is called as soon as the client connects to the server.

```swift
func websocketDidConnect(socket: WebSocketClient) {
    print("websocket is connected")
}
```

### websocketDidDisconnect

websocketDidDisconnect is called as soon as the client is disconnected from the server.

```swift
func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
	print("websocket is disconnected: \(error?.localizedDescription)")
}
```

### websocketDidReceiveMessage

websocketDidReceiveMessage is called when the client gets a text frame from the connection.

```swift
func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
	print("got some text: \(text)")
}
```

### websocketDidReceiveData

websocketDidReceiveData is called when the client gets a binary frame from the connection.

```swift
func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
	print("got some data: \(data.count)")
}
```

### Optional: websocketDidReceivePong *(required protocol: WebSocketPongDelegate)*

websocketDidReceivePong is called when the client gets a pong response from the connection. You need to implement the WebSocketPongDelegate protocol and set an additional delegate, eg: ` socket.pongDelegate = self`

