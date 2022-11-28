
//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Websocket.swift
//
//  Created by Dalton Cherry on 7/16/14.
//  Copyright (c) 2014-2017 Dalton Cherry.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation
import CoreFoundation
import SSCommonCrypto

public let WebsocketDidConnectNotification = "WebsocketDidConnectNotification"
public let WebsocketDidDisconnectNotification = "WebsocketDidDisconnectNotification"
public let WebsocketDisconnectionErrorKeyName = "WebsocketDisconnectionErrorKeyName"

//Standard WebSocket close codes
public enum CloseCode : UInt16 {
    case normal                 = 1000
    case goingAway              = 1001
    case protocolError          = 1002
    case protocolUnhandledType  = 1003
    // 1004 reserved.
    case noStatusReceived       = 1005
    //1006 reserved.
    case encoding               = 1007
    case policyViolated         = 1008
    case messageTooBig          = 1009
}

public enum ErrorType: Error {
    case outputStreamWriteError //output stream error during write
    case compressionError
    case invalidSSLError //Invalid SSL certificate
    case writeTimeoutError //The socket timed out waiting to be ready to write
    case protocolError //There was an error parsing the WebSocket frames
    case upgradeError //There was an error during the HTTP upgrade
    case closeError //There was an error during the close (socket probably has been dereferenced)
}

public struct WSError: Error {
    public let type: ErrorType
    public let message: String
    public let code: Int
}

//WebSocketClient is setup to be dependency injection for testing
public protocol WebSocketClient: class {
    var delegate: WebSocketDelegate? {get set}
    var disableSSLCertValidation: Bool {get set}
    var overrideTrustHostname: Bool {get set}
    var desiredTrustHostname: String? {get set}
    #if os(Linux)
    #else
    var security: SSLTrustValidator? {get set}
    var enabledSSLCipherSuites: [SSLCipherSuite]? {get set}
    #endif
    var isConnected: Bool {get}
    
    func connect()
    func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16)
    func write(string: String, completion: (() -> ())?)
    func write(data: Data, completion: (() -> ())?)
    func write(ping: Data, completion: (() -> ())?)
    func write(pong: Data, completion: (() -> ())?)
}

//implements some of the base behaviors
extension WebSocketClient {
    public func write(string: String) {
        write(string: string, completion: nil)
    }
    
    public func write(data: Data) {
        write(data: data, completion: nil)
    }
    
    public func write(ping: Data) {
        write(ping: ping, completion: nil)
    }

    public func write(pong: Data) {
        write(pong: pong, completion: nil)
    }
    
    public func disconnect() {
        disconnect(forceTimeout: nil, closeCode: CloseCode.normal.rawValue)
    }
}

//SSL settings for the stream
public struct SSLSettings {
    public let useSSL: Bool
    public let disableCertValidation: Bool
    public var overrideTrustHostname: Bool
    public var desiredTrustHostname: String?
    #if os(Linux)
    #else
    public let cipherSuites: [SSLCipherSuite]?
    #endif
}

public protocol WSStreamDelegate: class {
    func newBytesInStream()
    func streamDidError(error: Error?)
}

//This protocol is to allow custom implemention of the underlining stream. This way custom socket libraries (e.g. linux) can be used
public protocol WSStream {
    var delegate: WSStreamDelegate? {get set}
    func connect(url: URL, port: Int, timeout: TimeInterval, ssl: SSLSettings, completion: @escaping ((Error?) -> Void))
    func write(data: Data) -> Int
    func read() -> Data?
    func cleanup()
    #if os(Linux) || os(watchOS)
    #else
    func sslTrust() -> (trust: SecTrust?, domain: String?)
    #endif
}

open class FoundationStream : NSObject, WSStream, StreamDelegate  {
    private static let sharedWorkQueue = DispatchQueue(label: "com.vluxe.starscream.websocket", attributes: [])
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    public weak var delegate: WSStreamDelegate?
    let BUFFER_MAX = 4096
	
	public var enableSOCKSProxy = false
    
    public func connect(url: URL, port: Int, timeout: TimeInterval, ssl: SSLSettings, completion: @escaping ((Error?) -> Void)) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        let h = url.host! as NSString
        CFStreamCreatePairWithSocketToHost(nil, h, UInt32(port), &readStream, &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        #if os(watchOS) //watchOS us unfortunately is missing the kCFStream properties to make this work
        #else
            if enableSOCKSProxy {
                let proxyDict = CFNetworkCopySystemProxySettings()
                let socksConfig = CFDictionaryCreateMutableCopy(nil, 0, proxyDict!.takeRetainedValue())
                let propertyKey = CFStreamPropertyKey(rawValue: kCFStreamPropertySOCKSProxy)
                CFWriteStreamSetProperty(outputStream, propertyKey, socksConfig)
                CFReadStreamSetProperty(inputStream, propertyKey, socksConfig)
            }
        #endif
        
        guard let inStream = inputStream, let outStream = outputStream else { return }
        inStream.delegate = self
        outStream.delegate = self
        if ssl.useSSL {
            inStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            outStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            #if os(watchOS) //watchOS us unfortunately is missing the kCFStream properties to make this work
            #else
                var settings = [NSObject: NSObject]()
                if ssl.disableCertValidation {
                    settings[kCFStreamSSLValidatesCertificateChain] = NSNumber(value: false)
                }
                if ssl.overrideTrustHostname {
                    if let hostname = ssl.desiredTrustHostname {
                        settings[kCFStreamSSLPeerName] = hostname as NSString
                    } else {
                        settings[kCFStreamSSLPeerName] = kCFNull
                    }
                }
                inStream.setProperty(settings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
                outStream.setProperty(settings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
            #endif

            #if os(Linux)
            #else
            if let cipherSuites = ssl.cipherSuites {
                #if os(watchOS) //watchOS us unfortunately is missing the kCFStream properties to make this work
                #else
                if let sslContextIn = CFReadStreamCopyProperty(inputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySSLContext)) as! SSLContext?,
                    let sslContextOut = CFWriteStreamCopyProperty(outputStream, CFStreamPropertyKey(rawValue: kCFStreamPropertySSLContext)) as! SSLContext? {
                    let resIn = SSLSetEnabledCiphers(sslContextIn, cipherSuites, cipherSuites.count)
                    let resOut = SSLSetEnabledCiphers(sslContextOut, cipherSuites, cipherSuites.count)
                    if resIn != errSecSuccess {
                        completion(WSError(type: .invalidSSLError, message: "Error setting ingoing cypher suites", code: Int(resIn)))
                    }
                    if resOut != errSecSuccess {
                        completion(WSError(type: .invalidSSLError, message: "Error setting outgoing cypher suites", code: Int(resOut)))
                    }
                }
                #endif
            }
            #endif
        }
        
        CFReadStreamSetDispatchQueue(inStream, FoundationStream.sharedWorkQueue)
        CFWriteStreamSetDispatchQueue(outStream, FoundationStream.sharedWorkQueue)
        inStream.open()
        outStream.open()
        
        var out = timeout// wait X seconds before giving up
        FoundationStream.sharedWorkQueue.async { [weak self] in
            while !outStream.hasSpaceAvailable {
                usleep(100) // wait until the socket is ready
                out -= 100
                if out < 0 {
                    completion(WSError(type: .writeTimeoutError, message: "Timed out waiting for the socket to be ready for a write", code: 0))
                    return
                } else if let error = outStream.streamError {
                    completion(error)
                    return // disconnectStream will be called.
                } else if self == nil {
                    completion(WSError(type: .closeError, message: "socket object has been dereferenced", code: 0))
                    return
                }
            }
            completion(nil) //success!
        }
    }
    
    public func write(data: Data) -> Int {
        guard let outStream = outputStream else {return -1}
        let buffer = UnsafeRawPointer((data as NSData).bytes).assumingMemoryBound(to: UInt8.self)
        return outStream.write(buffer, maxLength: data.count)
    }
    
    public func read() -> Data? {
        guard let stream = inputStream else {return nil}
        let buf = NSMutableData(capacity: BUFFER_MAX)
        let buffer = UnsafeMutableRawPointer(mutating: buf!.bytes).assumingMemoryBound(to: UInt8.self)
        let length = stream.read(buffer, maxLength: BUFFER_MAX)
        if length < 1 {
            return nil
        }
        return Data(bytes: buffer, count: length)
    }
    
    public func cleanup() {
        if let stream = inputStream {
            stream.delegate = nil
            CFReadStreamSetDispatchQueue(stream, nil)
            stream.close()
        }
        if let stream = outputStream {
            stream.delegate = nil
            CFWriteStreamSetDispatchQueue(stream, nil)
            stream.close()