
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

//  https://en.wikipedia.org/wiki/Blowfish_(cipher)
//  Based on Paul Kocher implementation
//

public final class Blowfish {
    public enum Error: Swift.Error {
        /// Data padding is required
        case dataPaddingRequired
        /// Invalid key or IV
        case invalidKeyOrInitializationVector
        /// Invalid IV
        case invalidInitializationVector
    }

    public static let blockSize: Int = 8 // 64 bit
    public let keySize: Int

    private let blockMode: BlockMode
    private let padding: Padding
    private var decryptWorker: BlockModeWorker!
    private var encryptWorker: BlockModeWorker!

    private let N = 16 // rounds
    private var P: Array<UInt32>
    private var S: Array<Array<UInt32>>
    private let origP: Array<UInt32> = [
        0x243f6a88, 0x85a308d3, 0x13198a2e, 0x03707344, 0xa4093822,
        0x299f31d0, 0x082efa98, 0xec4e6c89, 0x452821e6, 0x38d01377,
        0xbe5466cf, 0x34e90c6c, 0xc0ac29b7, 0xc97c50dd, 0x3f84d5b5,
        0xb5470917, 0x9216d5d9, 0x8979fb1b,
    ]