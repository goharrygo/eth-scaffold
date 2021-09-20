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

/// A type that supports incremental updates. For example Digest or Cipher may be updatable
/// and calculate result incerementally.
public protocol Updatable {
    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process.
    /// - parameter isLast: Indicate if given chunk is the last one. No more updates after this call.
    /// - returns: Processed data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool) throws -> Array<UInt8>

    /// Update given bytes in chunks