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

```swift
func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
	print("Got pong! Maybe some data: \(data?.count)")
}
```

Or you can use closures.

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!)
//websocketDidConnect
socket.onConnect = {
    print("websocket is connected")
}
//websocketDidDisconnect
socket.onDisconnect = { (error: Error?) in
    print("websocket is disconnected: \(error?.localizedDescription)")
}
//websocketDidReceiveMessage
socket.onText = { (text: String) in
    print("got some text: \(text)")
}
//websocketDidReceiveData
socket.onData = { (data: Data) in
    print("got some data: \(data.count)")
}
//you could do onPong as well.
socket.connect()
```

One more: you can listen to socket connection and disconnection via notifications. Starscream posts `WebsocketDidConnectNotification` and `WebsocketDidDisconnectNotification`. You can find an `Error` that caused the disconection by accessing `WebsocketDisconnectionErrorKeyName` on notification `userInfo`.


## The delegate methods give you a simple way to handle data from the server, but how do you send data?

### write a binary frame

The writeData method gives you a simple way to send `Data` (binary) data to the server.

```swift
socket.write(data: data) //write some Data over the socket!
```

### write a string frame

The writeString method is the same as writeData, but sends text/string.

```swift
socket.write(string: "Hi Server!") //example on how to write text over the socket!
```

### write a ping frame

The writePing method is the same as write, but sends a ping control frame.

```swift
socket.write(ping: Data()) //example on how to write a ping control frame over the socket!
```

### write a pong frame


the writePong method is the same as writePing, but sends a pong control frame.

```swift
socket.write(pong: Data()) //example on how to write a pong control frame over the socket!
```

Starscream will automatically respond to incoming `ping` control frames so you do not need to manually send `pong`s.

However if for some reason you need to control this prosses you can turn off the automatic `ping` response by disabling `respondToPingWithPong`.

```swift
socket.respondToPingWithPong = false //Do not automaticaly respond to incoming pings with pongs.
```

In most cases you will not need to do this.

### disconnect

The disconnect method does what you would expect and closes the socket.

```swift
socket.disconnect()
```

### isConnected

Returns if the socket is connected or not.

```swift
if socket.isConnected {
  // do cool stuff.
}
```

### Custom Headers

You can also override the default websocket headers with your own custom ones like so:

```swift
var request = URLRequest(url: URL(string: "ws://localhost:8080/")!)
request.timeoutInterval = 5
request.setValue("someother protocols", forHTTPHeaderField: "Sec-WebSocket-Protocol")
request.setValue("14", forHTTPHeaderField: "Sec-WebSocket-Version")
request.setValue("Everything is Awesome!", forHTTPHeaderField: "My-Awesome-Header")
let socket = WebSocket(request: request)
```

### Custom HTTP Method

Your server may use a different HTTP method when connecting to the websocket:

```swift
var request = URLRequest(url: URL(string: "ws://localhost:8080/")!)
request.httpMethod = "POST"
request.timeoutInterval = 5
let socket = WebSocket(request: request)
```

### Protocols

If you need to specify a protocol, simple add it to the init:

```swift
//chat and superchat are the example protocols here
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!, protocols: ["chat","superchat"])
socket.delegate = self
socket.connect()
```

### Self Signed SSL

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!, protocols: ["chat","superchat"])

//set this if you want to ignore SSL cert validation, so a self signed SSL certificate can be used.
socket.disableSSLCertValidation = true
```

### SSL Pinning

SSL Pinning is also supported in Starscream.

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!, protocols: ["chat","superchat"])
let data = ... //load your certificate from disk
socket.security = SSLSecurity(certs: [SSLCert(data: data)], usePublicKeys: true)
//socket.security = SSLSecurity() //uses the .cer files in your app's bundle
```
You load either a `Data` blob of your certificate or you can use a `SecKeyRef` if you have a public key you want to use. The `usePublicKeys` bool is whether to use the certificates for validation or the public keys. The public keys will be extracted from the certificates automatically if `usePublicKeys` is choosen.

### SSL Cipher Suites

To use an SSL encrypted connection, you need to tell Starscream about the cipher suites your server supports. 

```swift
socket = WebSocket(url: URL(string: "wss://localhost:8080/")!, protocols: ["chat","superchat"])

// Set enabled cipher suites to AES 256 and AES 128
socket.enabledSSLCipherSuites = [TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256] 
```

If you don't know which cipher suites are supported by your server, you can try pointing [SSL Labs](https://www.ssllabs.com/ssltest/) at it and checking the results.

### Compression Extensions

Compression Extensions ([RFC 7692](https://tools.ietf.org/html/rfc7692)) is supported in Starscream.  Compression is enabled by default, however compression will only be used if it is supported by the server as well.  You may enable or disable compression via the `.enableCompression` property:

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!)
socket.enableCompression = false
```

Compression should be disabled if your application is transmitting already-compressed, random, or other uncompressable data.

### Custom Queue

A custom queue can be specified when delegate methods are called. By default `DispatchQueue.main` is used, thus making all delegate methods calls run on the main thread. It is important to note that all WebSocket processing is done on a background thread, only the delegate method calls are changed when modifying the queue. The actual processing is always on a background thread and will not pause your app.

```swift
socket = WebSocket(url: URL(string: "ws://localhost:8080/")!, protocols: ["chat","superchat"])
//create a custom queue
so