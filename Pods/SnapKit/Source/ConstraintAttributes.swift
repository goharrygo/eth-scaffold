//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif


internal struct ConstraintAttributes : OptionSet {
    
    internal init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    internal init(_ rawValue: UInt) {
        self.init(rawValue: rawValue)
    }
    internal init(nilLiteral: ()) {
        self.rawValue = 0
    }
    
    internal private(set) var rawValue: UInt
    internal static var allZeros: ConstraintAttributes { return self.init(0) }
    internal static func convertFromNilLiteral() -> ConstraintAttributes { return self.init(0) }
    internal var boolValue: Bool { return self.rawValue != 0 }
    
    internal func toRaw() -> UInt { return self.rawValue }
    internal static func fromRaw(_ raw: UInt) -> ConstraintAttributes? { return self.init(raw) }
    internal static func fromMask(_ raw: UInt) -> ConstraintAttributes { return self.init(raw) }
    
    // normal
    
    internal static var none: ConstraintAttributes { return self.init(0) }
    internal static var left: ConstraintAttributes { return self.init(1) }
    internal static var top: ConstraintAttributes {  return self.init(2) }
    internal static var right: ConstraintAttributes { return self.init(4) }
    internal static var bottom: ConstraintAttributes { return self.init(8) }
    internal static var leading: ConstraintAttributes { return self.init(16) }
    internal static var trailing: ConstraintAttributes { return self.init(32) }
    internal static var width: ConstraintAttributes { return self.init(64) }
    internal static var height: ConstraintAttributes { return self.init(128) }
    internal static var centerX: ConstraintAttributes { return self.init(256) }
    internal static var centerY: ConstraintAttributes { return self.init(512) }
    internal static var lastBaseline: ConstraintAttributes { return self.init(1024) }
    
    @available(iOS 8.0, OSX 10.11, *)
    internal static var firstBaseline: ConstraintAttributes { return self.init(2048) }
    
    @available(iOS 8.0, *)
    internal static var leftMargin: ConstraintAttributes { return 