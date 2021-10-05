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
     - Continuous: Continuously scrolls left (with a pause at the