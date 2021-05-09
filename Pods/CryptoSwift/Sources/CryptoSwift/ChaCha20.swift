
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

//  https://tools.ietf.org/html/rfc7539
//

public final class ChaCha20: BlockCipher {
    public enum Error: Swift.Error {
        case invalidKeyOrInitializationVector
    }

    public static let blockSize = 64 // 512 / 8
    public let keySize: Int

    fileprivate let key: Key
    fileprivate var counter: Array<UInt8>

    public init(key: Array<UInt8>, iv nonce: Array<UInt8>) throws {
        precondition(nonce.count == 12 || nonce.count == 8)

        if key.count != 32 {
            throw Error.invalidKeyOrInitializationVector
        }

        self.key = Key(bytes: key)
        keySize = self.key.count

        if nonce.count == 8 {
            counter = [0, 0, 0, 0, 0, 0, 0, 0] + nonce
        } else {
            counter = [0, 0, 0, 0] + nonce
        }

        assert(counter.count == 16)
    }

    /// https://tools.ietf.org/html/rfc7539#section-2.3.
    fileprivate func core(block: inout Array<UInt8>, counter: Array<UInt8>, key: Array<UInt8>) {
        precondition(block.count == ChaCha20.blockSize)
        precondition(counter.count == 16)
        precondition(key.count == 32)

        let j0: UInt32 = 0x61707865
        let j1: UInt32 = 0x3320646e // 0x3620646e sigma/tau
        let j2: UInt32 = 0x79622d32
        let j3: UInt32 = 0x6b206574
        let j4: UInt32 = UInt32(bytes: key[0..<4]).bigEndian
        let j5: UInt32 = UInt32(bytes: key[4..<8]).bigEndian
        let j6: UInt32 = UInt32(bytes: key[8..<12]).bigEndian
        let j7: UInt32 = UInt32(bytes: key[12..<16]).bigEndian
        let j8: UInt32 = UInt32(bytes: key[16..<20]).bigEndian
        let j9: UInt32 = UInt32(bytes: key[20..<24]).bigEndian
        let j10: UInt32 = UInt32(bytes: key[24..<28]).bigEndian
        let j11: UInt32 = UInt32(bytes: key[28..<32]).bigEndian
        let j12: UInt32 = UInt32(bytes: counter[0..<4]).bigEndian
        let j13: UInt32 = UInt32(bytes: counter[4..<8]).bigEndian
        let j14: UInt32 = UInt32(bytes: counter[8..<12]).bigEndian
        let j15: UInt32 = UInt32(bytes: counter[12..<16]).bigEndian

        var (x0, x1, x2, x3, x4, x5, x6, x7) = (j0, j1, j2, j3, j4, j5, j6, j7)
        var (x8, x9, x10, x11, x12, x13, x14, x15) = (j8, j9, j10, j11, j12, j13, j14, j15)

        for _ in 0..<10 { // 20 rounds
            x0 = x0 &+ x4
            x12 ^= x0
            x12 = (x12 << 16) | (x12 >> 16)
            x8 = x8 &+ x12
            x4 ^= x8
            x4 = (x4 << 12) | (x4 >> 20)
            x0 = x0 &+ x4
            x12 ^= x0
            x12 = (x12 << 8) | (x12 >> 24)
            x8 = x8 &+ x12
            x4 ^= x8
            x4 = (x4 << 7) | (x4 >> 25)
            x1 = x1 &+ x5
            x13 ^= x1
            x13 = (x13 << 16) | (x13 >> 16)
            x9 = x9 &+ x13
            x5 ^= x9
            x5 = (x5 << 12) | (x5 >> 20)
            x1 = x1 &+ x5
            x13 ^= x1
            x13 = (x13 << 8) | (x13 >> 24)
            x9 = x9 &+ x13
            x5 ^= x9
            x5 = (x5 << 7) | (x5 >> 25)
            x2 = x2 &+ x6
            x14 ^= x2
            x14 = (x14 << 16) | (x14 >> 16)
            x10 = x10 &+ x14
            x6 ^= x10
            x6 = (x6 << 12) | (x6 >> 20)
            x2 = x2 &+ x6
            x14 ^= x2
            x14 = (x14 << 8) | (x14 >> 24)
            x10 = x10 &+ x14
            x6 ^= x10
            x6 = (x6 << 7) | (x6 >> 25)