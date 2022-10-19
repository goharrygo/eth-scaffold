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

public extension LayoutConstraint {
    
    override public var description: String {
        var description = "<"
        
        description += descriptionForObject(self)
        
        if let firstItem = conditionalOptional(from: self.firstItem) {
            description += " \(descriptionForObject(firstItem))"
        }
        
        if self.firstAttribute != .notAnAttribute {
            description += ".\(descriptionForAttribute(self.firstAttribute))"
        }
        
        description += " \(descriptionForRelation(self.relation))"
        
        if let secondItem = self.secondItem {
            description += " \(descriptionForObject(secondItem))"
        }
        
        if self.secondAttribute != .notAnAttribute {
            description += ".\(descriptionForAttribute(self.secondAttribute))"
        }
        
        if self.multiplier != 1.0 {
            description += " * \(self.multiplier)"
        }
        
        if self.secondAttribute == .notAnAttribute {
            description += " \(self.constant)"
        } else {
            if self.constant > 0.0 {
                description += " + \(self.constant)"
            } else if self.constant < 0.0 {
                description += " - \(abs(self.constant))"
            }
        }
        
       