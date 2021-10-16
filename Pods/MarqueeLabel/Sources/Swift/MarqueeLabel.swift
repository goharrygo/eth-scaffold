//
//  MarqueeLabel.swift
//
//  Created by Charles Powell on 8/6/14.
//  Copyright (c) 2015 Charles Powell. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable

open class MarqueeLabel: UILabel, CAAnimationDelegate {
    
    /**
     An enum that defines the types of `MarqueeLabel` scrolling
     
     - Left: Scrolls left after the specified delay, and does not return to the original position.
     - LeftRight: Scrolls left first, then back right to the original position.
     - Right: Scrolls right after the specified delay, and does not return to the original position.
     - RightLeft: Scrolls right first, then back left to the original position.
     - Continuous: Continuously scrolls left (with a pause at the original position if animationDelay is set).
     - ContinuousReverse: Continuously scrolls right (with a pause at the original position if animationDelay is set).
     */
    public enum MarqueeType {
        case left
        case leftRight
        case right
        case rightLeft
        case continuous
        case continuousReverse
    }
    
    //
    // MARK: - Public properties
    //
    
    /**
     Defines the direction and method in which the `MarqueeLabel` instance scrolls.
     `MarqueeLabel` supports six default types of scrolling: `Left`, `LeftRight`, `Right`, `RightLeft`, `Continuous`, and `ContinuousReverse`.
     
     Given the nature of how text direction works, the options for the `type` property require specific text alignments
     and will set the textAlignment property accordingly.
     
     - `LeftRight` and `Left` types are ONLY compatible with a label text alignment of `NSTextAlignmentLeft`.
     - `RightLeft` and `Right` types are ONLY compatible with a label text alignment of `NSTextAlignmentRight`.
     - `Continuous` does not require a text alignment (it is effectively centered).
     - `ContinuousReverse` does not require a text alignment (it is effectively centered).
     
     Defaults to `Continuous`.
     
     - SeeAlso: textAlignment
     */
    open var type: MarqueeType = .continuous {
        didSet {
            if type == oldValue {
                return
            }
            updateAndScroll()
        }
    }
    
    /**
     An optional custom scroll "sequence", defined by an array of `ScrollStep` or `FadeStep` instances. A sequence
     defines a single scroll/animation loop, which will continue to be automatically repeated like the default types.
     
     A `type` value is still required when using a custom sequence. The `type` value defines the `home` and `away`
     values used in the `ScrollStep` instances, and the `type` value determines which way the label will scroll.
     
     When a custom sequence is not supplied, the default sequences are used per the defined `type`.
     
     `ScrollStep` steps are the primary step types, and define the position of the label at a given time in the sequence.
     `FadeStep` steps are secondary steps that define the edge fade state (leading, trailing, or both) around the `ScrollStep`
     steps.
     
     Defaults to nil.
     
     - Attention: Use of the `scrollSequence` property requires understanding of how MarqueeLabel works for effective
     use. As a reference, it is suggested to review the methodology used to build the sequences for the default types.
     
     - SeeAlso: type
 