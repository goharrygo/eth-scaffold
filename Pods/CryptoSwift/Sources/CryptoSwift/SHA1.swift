
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

public final class SHA1: DigestType {
    static let digestLength: Int = 20 // 160 / 8
    static let blockSize: Int = 64
    fileprivate static let hashInitialValue: ContiguousArray<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0]

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash: ContiguousArray<UInt32> = SHA1.hashInitialValue

    public init() {
    }

    public func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            return []
        }
    }

    fileprivate func process(block chunk: ArraySlice<UInt8>, currentHash hh: inout ContiguousArray<UInt32>) {
        // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 32-bit words into eighty 32-bit words:
        let M = UnsafeMutablePointer<UInt32>.allocate(capacity: 80)
        M.initialize(repeating: 0, count: 80)
        defer {
            M.deinitialize(count: 80)
            M.deallocate()
        }

        for x in 0..<80 {
            switch x {
            case 0...15:
                let start = chunk.startIndex.advanced(by: x * 4) // * MemoryLayout<UInt32>.size
                M[x] = UInt32(bytes: chunk, fromIndex: start)
                break
            default: