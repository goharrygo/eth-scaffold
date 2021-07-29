//
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

//  http://tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04#section-4
//  nacl/crypto_onetimeauth/poly1305/ref/auth.c
//
///  Poly1305 takes a 32-byte, one-time key and a message and produces a 16-byte tag that authenticates the
///  message such that an attacker has a negligible chance of producing a valid tag for an inauthentic message.

public final class Poly1305: Authenticator {
    public enum Error: Swift.Error {
        case authenticateError
    }

    public static let blockSize: Int = 16

    private let key: SecureBytes

    /// - parameter key: 32-byte key
    public init(key: Array<UInt8>) {
        self.key = SecureBytes(bytes: key)
    }

    private func squeeze(h: inout Array<UInt32>) {
        assert(h.count == 17)
        var u: UInt32 = 0
        for j in 0..<16 {
            u = u &+ h[j]
            h[j] = u & 255
            u = u >> 8
        }

        u = u &+ h[16]
        h[16]