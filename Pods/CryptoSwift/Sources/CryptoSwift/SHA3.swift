
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

//  http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf
//  http://keccak.noekeon.org/specs_summary.html
//

#if os(Linux) || os(Android) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

public final class SHA3: DigestType {
    let round_constants: Array<UInt64> = [
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a, 0x8000000080008000,
        0x000000000000808b, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
        0x000000000000008a, 0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
        0x8000000000008002, 0x8000000000000080, 0x000000000000800a, 0x800000008000000a,
        0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
    ]

    public let blockSize: Int
    public let digestLength: Int
    public let markByte: UInt8

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var accumulatedHash: Array<UInt64>

    public enum Variant {
        case sha224, sha256, sha384, sha512, keccak224, keccak256, keccak384, keccak512

        var digestLength: Int {
            return 100 - (blockSize / 2)
        }

        var blockSize: Int {
            return (1600 - outputLength * 2) / 8
        }

        var markByte: UInt8 {
            switch self {
            case .sha224, .sha256, .sha384, .sha512:
                return 0x06 // 0x1F for SHAKE
            case .keccak224, .keccak256, .keccak384, .keccak512:
                return 0x01
            }
        }

        public var outputLength: Int {
            switch self {
            case .sha224, .keccak224:
                return 224
            case .sha256, .keccak256:
                return 256
            case .sha384, .keccak384:
                return 384
            case .sha512, .keccak512:
                return 512
            }
        }
    }

    public init(variant: SHA3.Variant) {
        blockSize = variant.blockSize
        digestLength = variant.digestLength
        markByte = variant.markByte
        accumulatedHash = Array<UInt64>(repeating: 0, count: digestLength)
    }

    public func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            return []
        }
    }

    ///  1. For all pairs (x,z) such that 0≤x<5 and 0≤z<w, let
    ///     C[x,z]=A[x, 0,z] ⊕ A[x, 1,z] ⊕ A[x, 2,z] ⊕ A[x, 3,z] ⊕ A[x, 4,z].
    ///  2. For all pairs (x, z) such that 0≤x<5 and 0≤z<w let
    ///     D[x,z]=C[(x1) mod 5, z] ⊕ C[(x+1) mod 5, (z –1) mod w].
    ///  3. For all triples (x, y, z) such that 0≤x<5, 0≤y<5, and 0≤z<w, let