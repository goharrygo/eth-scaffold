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
     - SeeAlso: ScrollStep
     - SeeAlso: FadeStep
     */
    open var scrollSequence: Array<MarqueeStep>?
    
    /**
     Specifies the animation curve used in the scrolling motion of the labels.
     Allowable options:
     
     - `UIViewAnimationOptionCurveEaseInOut`
     - `UIViewAnimationOptionCurveEaseIn`
     - `UIViewAnimationOptionCurveEaseOut`
     - `UIViewAnimationOptionCurveLinear`
     
     Defaults to `UIViewAnimationOptionCurveEaseInOut`.
     */
    open var animationCurve: UIViewAnimationCurve = .linear
    
    /**
     A boolean property that sets whether the `MarqueeLabel` should behave like a normal `UILabel`.
     
     When set to `true` the `MarqueeLabel` will behave and look like a normal `UILabel`, and  will not begin any scrolling animations.
     Changes to this property take effect immediately, removing any in-flight animation as well as any edge fade. Note that `MarqueeLabel`
     will respect the current values of the `lineBreakMode` and `textAlignment`properties while labelized.
     
     To simply prevent automatic scrolling, use the `holdScrolling` property.
     
     Defaults to `false`.
     
     - SeeAlso: holdScrolling
     - SeeAlso: lineBreakMode
     - Note: The label will not automatically scroll when this property is set to `true`.
     - Warning: The UILabel default setting for the `lineBreakMode` property is `NSLineBreakByTruncatingTail`, which truncates
     the text adds an ellipsis glyph (...). Set the `lineBreakMode` property to `NSLineBreakByClipping` in order to avoid the
     ellipsis, especially if using an edge transparency fade.
     */
    @IBInspectable open var labelize: Bool = false {
        didSet {
            if labelize != oldValue {
                updateAndScroll()
            }
        }
    }
    
    /**
     A boolean property that sets whether the `MarqueeLabel` should hold (prevent) automatic label scrolling.
     
     When set to `true`, `MarqueeLabel` will not automatically scroll even its text is larger than the specified frame,
     although the specified edge fades will remain.
     
     To set `MarqueeLabel` to act like a normal UILabel, use the `labelize` property.
     
     Defaults to `false`.
     
     - Note: The label will not automatically scroll when this property is set to `true`.
     - SeeAlso: labelize
     */
    @IBInspectable open var holdScrolling: Bool = false {
        didSet {
            if holdScrolling != oldValue {
                if oldValue == true && !(awayFromHome || labelize || tapToScroll ) && labelShouldScroll() {
                    updateAndScroll(true)
                }
            }
        }
    }
    
    /**
     A boolean property that sets whether the `MarqueeLabel` should only begin a scroll when tapped.
     
     If this property is set to `true`, the `MarqueeLabel` will only begin a scroll animation cycle when tapped. The label will
     not automatically being a scroll. This setting overrides the setting of the `holdScrolling` property.
     
     Defaults to `false`.
     
     - Note: The label will not automatically scroll when this property is set to `false`.
     - SeeAlso: holdScrolling
     */
    @IBInspectable open var tapToScroll: Bool = false {
        didSet {
            if tapToScroll != oldValue {
                if tapToScroll {
                    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MarqueeLabel.labelWasTapped(_:)))
                    self.addGestureRecognizer(tapRecognizer)
                    isUserInteractionEnabled = true
                } else {
                    if let recognizer = self.gestureRecognizers!.first as UIGestureRecognizer? {
                        self.removeGestureRecognizer(recognizer)
                    }
                    isUserInteractionEnabled = false
                }
            }
        }
    }
    
    /**
     A read-only boolean property that indicates if the label's scroll animation has been paused.
     
     - SeeAlso: pauseLabel
     - SeeAlso: unpauseLabel
     */
    open var isPaused: Bool {
        return (sublabel.layer.speed == 0.0)
    }
    
    /**
     A boolean property that indicates if the label is currently away from the home location.
     
     The "home" location is the traditional location of `UILabel` text. This property essentially reflects if a scroll animation is underway.
     */
    open var awayFromHome: Bool {
        if let presentationLayer = sublabel.layer.presentation() {
            return !(presentationLayer.position.x == homeLabelFrame.origin.x)
        }
        
        return false
    }
    
    /**
     The `MarqueeLabel` scrolling speed may be defined by one of two ways:
     - Rate(CGFloat): The speed is defined by a rate of motion, in units of points per second.
     - Duration(CGFloat): The speed is defined by the time to complete a scrolling animation cycle, in units of seconds.
     
     Each case takes an associated `CGFloat` value, which is the rate/duration desired.
     */
    public enum SpeedLimit {
        case rate(CGFloat)
        case duration(CGFloat)
        
        var value: CGFloat {
            switch self {
            case .rate(let rate):
                return rate
            case .duration(let duration):
                return duration
            }
        }
    }
    
    /**
     Defines the speed of the `MarqueeLabel` scrolling animation.
     
     The speed is set by specifying a case of the `SpeedLimit` enum along with an associated value.
     
     - SeeAlso: SpeedLimit
     */
    open var speed: SpeedLimit = .duration(7.0) {
        didSet {
            switch (speed, oldValue) {
            case (.rate(let a), .rate(let b)) where a == b:
                return
            case (.duration(let a), .duration(let b)) where a == b:
                return
            default:
                updateAndScroll()
            }
        }
    }
    
    @available(*, deprecated : 2.6, message : "Use speed property instead")
    @IBInspectable open var scrollDuration: CGFloat {
        get {
            switch speed {
            case .duration(let duration): return duration
            case .rate(_): return 0.0
            }
        }
        set {
            speed = .duration(newValue)
        }
    }
    
    @available(*, deprecated : 2.6, message : "Use speed property instead")
    @IBInspectable open var scrollRate: CGFloat {
        get {
            switch speed {
            case .duration(_): return 0.0
            case .rate(let rate): return rate
            }
        }
        set {
            speed = .rate(newValue)
        }
    }
    
    /**
     A buffer (offset) between the leading edge of the label text and the label frame.
     
     This property adds additional space between the leading edge of the label text and the label frame. The
     leading edge is the edge of the label text facing the direction of scroll (i.e. the edge that animates
     offscreen first during scrolling).
     
     Defaults to `0`.
     
     - Note: The value set to this property affects label positioning at all times (including when `labelize` is set to `true`),
     including when the text string length is short enough that the label does not need to scroll.
     - Note: For Continuous-type labels, the smallest value of `leadingBuffer`, `trailingBuffer`, and `fadeLength`
     is used as spacing between the two label instances. Zero is an allowable value for all three properties.
     
     - SeeAlso: trailingBuffer
     */
    @IBInspectable open var leadingBuffer: CGFloat = 0.0 {
        didSet {
            if leadingBuffer != oldValue {
                updateAndScroll()
            }
        }
    }
    
    /**
     A buffer (offset) between the trailing edge of the label text and the label frame.
     
     This property adds additional space (buffer) between the trailing edge of the label text and the label frame. The
     trailing edge is the edge of the label text facing away from the direction of scroll (i.e. the edge that animates
     offscreen last during scrolling).
     
     Defaults to `0`.
     
     - Note: The value set to this property has no effect when the `labelize` property is set to `true`.
     
     - Note: For Continuous-type labels, the smallest value of `leadingBuffer`, `trailingBuffer`, and `fadeLength`
     is used as spacing between the two label instances. Zero is an allowable value for all three properties.
     
     - SeeAlso: leadingBuffer
     */
    @IBInspectable open var trailingBuffer: CGFloat = 0.0 {
        didSet {
            if trailingBuffer != oldValue {
                updateAndScroll()
            }
        }
    }
    
    /**
     The length of transparency fade at the left and right edges of the frame.
     
     This propery sets the size (in points) of the view edge transparency fades on the left and right edges of a `MarqueeLabel`. The
     transparency fades from an alpha of 1.0 (fully visible) to 0.0 (fully transparent) over this distance. Values set to this property
     will be sanitized to prevent a fade length greater than 1/2 of the frame width.
     
     Defaults to `0`.
     */
    @IBInspectable open var fadeLength: CGFloat = 0.0 {
        didSet {
            if fadeLength != oldValue {
                applyGradientMask(fadeLength, animated: true)
                updateAndScroll()
            }
        }
    }
    
    
    /**
     The length of delay in seconds that the label pauses at the completion of a scroll.
     */
    @IBInspectable open var animationDelay: CGFloat = 1.0
    
    
    /** The read-only/computed duration of the scroll animation (not including delay).
     
     The value of this property is calculated from the value set to the `speed` property. If a duration-type speed is
     used to set the label animation speed, `animationDuration` will be equivalent to that value.
     */
    public var animationDuration: CGFloat {
        switch self.speed {
        case .rate(let rate):
            return CGFloat(fabs(self.awayOffset) / rate)
        case .duration(let duration):
            return duration
        }
    }
    
    //
    // MARK: - Class Functions and Helpers
    //
    
    /**
     Convenience method to restart all `MarqueeLabel` instances that have the specified view controller in their next responder chain.
    
     - Parameter controller: The view controller for which to restart all `MarqueeLabel` instances.
    
     - Warning: View controllers that appear with animation (such as from underneath a modal-style controller) can cause some `MarqueeLabel` text
     position "jumping" when this method is used in `viewDidAppear` if scroll animations are already underway. Use this method inside `viewWillAppear:`
     instead to avoid this problem.
    
     - Warning: This method may not function properly if passed the parent view controller when using view controller containment.
    
     - SeeAlso: restartLabel
     - SeeAlso: controllerViewDidAppear:
     - SeeAlso: controllerViewWillAppear:
     */
    open class func restartLabelsOfController(_ controller: UIViewController) {
        MarqueeLabel.notifyController(controller, message: .Restart)
    }
    
    /**
     Convenience method to restart all `MarqueeLabel` instances that have the specified view controller in their next responder chain.
     
     Alternative to `restartLabelsOfController`. This method is retained for backwards compatibility and future enhancements.
     
     - Parameter controller: The view controller that will appear.
     - SeeAlso: restartLabel
     - SeeAlso: controllerViewDidAppear
     */
    open class func controllerViewWillAppear(_ controller: UIViewController) {
        MarqueeLabel.restartLabelsOfController(controller)
    }
    
    /**
     Convenience method to restart all `MarqueeLabel` instances that have the specified view controller in their next responder chain.
     
     Alternative to `restartLabelsOfController`. This method is retained for backwards compatibility and future enhancements.
     
     - Parameter controller: The view controller that did appear.
     - SeeAlso: restartLabel
     - SeeAlso: controllerViewWillAppear
     */
    open class func controllerViewDidAppear(_ controller: UIViewController) {
        MarqueeLabel.restartLabelsOfController(controller)
    }
    
    /**
     Labelizes all `MarqueeLabel` instances that have the specified view controller in their next responder chain.
    
     The `labelize` property of all recognized `MarqueeLabel` instances will be set to `true`.
     
     - Parameter controller: The view controller for which all `MarqueeLabel` instances should be labelized.
     - SeeAlso: labelize
     */
    open class func controllerLabelsLabelize(_ controller: UIViewController) {
        MarqueeLabel.notifyController(controller, message: .Labelize)
    }
    
    /**
     De-labelizes all `MarqueeLabel` instances that have the specified view controller in their next responder chain.
     
     The `labelize` property of all recognized `MarqueeLabel` instances will be set to `false`.
     
     - Parameter controller: The view controller for which all `MarqueeLabel` instances should be de-labelized.
     - SeeAlso: labelize
     */
    open class func controllerLabelsAnimate(_ controller: UIViewController) {
        MarqueeLabel.notifyController(controller, message: .Animate)
    }

    
    //
    // MARK: - Initialization
    //
    
    /**
     Returns a newly initialized `MarqueeLabel` instance with the specified scroll rate and edge transparency fade length.
    
     - Parameter frame: A rectangle specifying the initial location and size of the view in its superview's coordinates. Text (for the given font, font size, etc.) that does not fit in this frame will automatically scroll.
     - Parameter pixelsPerSec: A rate of scroll for the label scroll animation. Must be non-zero. Note that this will be the peak (mid-transition) rate for ease-type animation.
     - Parameter fadeLength: A length of transparency fade at the left and right edges of the `MarqueeLabel` instance's frame.
     - Returns: An initialized `MarqueeLabel` object or nil if the object couldn't be created.
     - SeeAlso: fadeLength
     */
    public init(frame: CGRect, rate: CGFloat, fadeLength fade: CGFloat) {
        speed = .rate(rate)
        fadeLength = CGFloat(min(fade, frame.size.width/2.0))
        super.init(frame: frame)
        setup()
    }
    
    /**
     Returns a newly initialized `MarqueeLabel` instance with the specified scroll rate and edge transparency fade length.
     
     - Parameter frame: A rectangle specifying the initial location and size of the view in its superview's coordinates. Text (for the given font, font size, etc.) that does not fit in this frame will automatically scroll.
     - Parameter scrollDuration: A scroll duration the label scroll animation. Must be non-zero. This will be the duration that the animation takes for one-half of the scroll cycle in the case of left-right and right-left marquee types, and for one loop of a continuous marquee type.
     - Parameter fadeLength: A length of transparency fade at the left and right edges of the `MarqueeLabel` instance's frame.
     - Returns: An initialized `MarqueeLabel` object or nil if the object couldn't be created.
     - SeeAlso: fadeLength
     */
    public init(frame: CGRect, duration: CGFloat, fadeLength fade: CGFloat) {
        speed = .duration(duration)
        fadeLength = CGFloat(min(fade, frame.size.width/2.0))
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    /**
     Returns a newly initialized `MarqueeLabel` instance.
     
     The default scroll duration of 7.0 seconds and fade length of 0.0 are used.
     
     - Parameter frame: A rectangle specifying the initial location and size of the view in its superview's coordinates. Text (for the given font, font size, etc.) that does not fit in this frame will automatically scroll.
     - Returns: An initialized `MarqueeLabel` object or nil if the object couldn't be created.
    */
    convenience public override init(frame: CGRect) {
        self.init(frame: frame, duration:7.0, fadeLength:0.0)
    }
    
    private func setup() {
        // Create sublabel
        sublabel = UILabel(frame: self.bounds)
        sublabel.tag = 700
        sublabel.layer.anchorPoint = CGPoint.zero

        // Add sublabel
        addSubview(sublabel)
        
        // Configure self
        super.clipsToBounds = true
        super.numberOfLines = 1
        
        // Add notification observers
        // Custom class notifications
        NotificationCenter.default.addObserver(self, selector: #selector(MarqueeLabel.restartForViewController(_:)), name: NSNotification.Name(rawValue: MarqueeKeys.Restart.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MarqueeLabel.labelizeForController(_:)), name: NSNotification.Name(rawValue: MarqueeKeys.Labelize.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MarqueeLabel.animateForController(_:)), name: NSNotification.Name(rawValue: MarqueeKeys.Animate.rawValue), object: nil)
        // UIApplication state notifications
        NotificationCenter.default.addObserver(self, selector: #selector(MarqueeLabel.restartLabel), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MarqueeLabel.shutdownLabel), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        forwardPropertiesToSublabel()
    }
    
    @available(iOS 8.0, *)
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        forwardPropertiesToSublabel()
    }
    
    private func forwardPropertiesToSublabel() {
        /*
        Note that this method is currently ONLY called from awakeFromNib, i.e. when
        text properties are set via a Storyboard. As the Storyboard/IB doesn't currently
        support attributed strings, there's no need to "forward" the super attributedString value.
        */
        
        // Since we're a UILabel, we actually do implement all of UILabel's properties.
        // We don't care about these values, we just want to forward them on to our sublabel.
        let properties = ["baselineAdjustment", "enabled", "highlighted", "highlightedTextColor",
                          "minimumFontSize", "shadowOffset", "textAlignment",
                          "userInteractionEnabled", "adjustsFontSizeToFitWidth",
                          "lineBreakMode", "numberOfLines", "contentMode"]
        
        // Iterate through properties
        sublabel.text = super.text
        sublabel.font = super.font
        sublabel.textColor = super.textColor
        sublabel.backgroundColor = super.backgroundColor ?? UIColor.clear
        sublabel.shadowColor = super.shadowColor
        sublabel.shadowOffset = super.shadowOffset
        for prop in properties {
            let value = super.value(forKey: prop)
            sublabel.setValue(value, forKeyPath: prop)
        }
    }
    
    //
    // MARK: - MarqueeLabel Heavy Lifting
    //

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        updateAndScroll(true)
    }

    override open func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            shutdownLabel()
        }
    }
    
    override open func didMoveToWindow() {
        if self.window == nil {
            shutdownLabel()
        } else {
            updateAndScroll()
        }
    }
    
    private func updateAndScroll() {
        updateAndScroll(true)
    }
    
    private func updateAndScroll(_ shouldBeginScroll: Bool) {
        // Check if scrolling can occur
        if !labelReadyForScroll() {
            return
        }
        
        // Calculate expected size
        let expectedLabelSize = sublabelSize()
        
        // Invalidate intrinsic size
        invalidateIntrinsicContentSize()
        
        // Move label to home
        returnLabelToHome()
        
        // Check if label should scroll
        // Note that the holdScrolling propery does not affect this
        if !labelShouldScroll() {
            // Set text alignment and break mode to act like a normal label
            sublabel.textAlignment = super.textAlignment
            sublabel.lineBreakMode = super.lineBreakMode
            
            let labelFrame: CGRect
            switch type {
            case .continuousReverse, .rightLeft:
                labelFrame = bounds.divided(atDistance: leadingBuffer, from: CGRectEdge.maxXEdge).remainder.integral
            default:
                labelFrame = CGRect(x: leadingBuffer, y: 0.0, width: bounds.size.width - leadingBuffer, height: bounds.size.height).integral
            }
            
            homeLabelFrame = labelFrame
            awayOffset = 0.0
            
            // Remove an additional sublabels (for continuous types)
            repliLayer?.instanceCount = 1;
            
            // Set the sublabel frame to calculated labelFrame
            sublabel.frame = labelFrame
            
            // Remove fade, as by definition none is needed in this case
            removeGradientMask()
            
            return
        }
        
        // Label DOES need to scroll
        
        // Spacing between primary and second sublabel must be at least equal to leadingBuffer, and at least equal to the fadeLength
        let minTrailing = max(max(leadingBuffer, trailingBuffer), fadeLength)
        
        // Determine positions and generate scroll steps
        let sequence: [MarqueeStep]
        
        switch type {
        case .continuous, .continuousReverse:
            if (type == .continuous) {
                homeLabelFrame = CGRect(x: leadingBuffer, y: 0.0, width: expectedLabelSize.width, height: bounds.size.height).integral
                awayOffset = -(homeLabelFrame.size.width + minTrailing)
            } else { // .ContinuousReverse
                homeLabelFrame = CGRect(x: bounds.size.width - (expectedLabelSize.width + leadingBuffer), y: 0.0, width: expectedLabelSize.width, height: bounds.size.height).integral
                awayOffset = (homeLabelFrame.size.width + minTrailing)
            }
            
            // Find when the lead label will be totally offscreen
            let offsetDistance = awayOffset
            let offscreenAmount = homeLabelFrame.size.width
            let startFadeFraction = fabs(offscreenAmount / offsetDistance)
            // Find when the animation will hit that point
            let startFadeTimeFraction = timingFunctionForAnimationCurve(animationCurve).durationPercentageForPositionPercentage(startFadeFraction, duration: (animationDelay + animationDuration))
            let startFadeTime = startFadeTimeFraction * animationDuration
            
            sequence = scrollSequence ?? [
                ScrollStep(timeStep: 0.0, position: .home, edgeFades: .trailing),                   // Starting point, at home, with trailing fade
                ScrollStep(timeStep: animationDelay, position: .home, edgeFades: .trailing),        // Delay at home, maintaining fade state
                FadeStep(timeStep: 0.2, edgeFades: [.leading, .trailing]),                          // 0.2 sec after scroll start, fade leading edge in as well
                FadeStep(timeStep: (startFadeTime - animationDuration),                             // Maintain fade state until just before reaching end of scroll animation
                         edgeFades: [.leading, .trailing]),
                ScrollStep(timeStep: animationDuration, timingFunction: animationCurve,             // Ending point (back at home), with animationCurve transition, with trailing fade
                           position: .away, edgeFades: .trailing)
            ]
            
            // Set frame and text
            sublabel.frame = homeLabelFrame
            
            // Configure replication
            repliLayer?.instanceCount = 2
            repliLayer?.instanceTransform = CATransform3DMakeTranslation(-awayOffset, 0.0, 0.0)
            
        case .leftRight, .left, .rightLeft, .right:
            if (type == .leftRight || type == .left) {
                homeLabelFrame = CGRect(x: leadingBuffer, y: 0.0, width: expectedLabelSize.width, height: bounds.size.height).integral
                awayOffset = bounds.size.width - (expectedLabelSize.width + leadingBuffer + trailingBuffer)
                // Enforce text alignment for this type
                sublabel.textAlignment = NSTextAlignment.left
            } else {
                homeLabelFrame = CGRect(x: bounds.size.width - (expectedLabelSize.width + leadingBuffer), y: 0.0, width: expectedLabelSize.width, height: bounds.size.height).integral
                awayOffset = (expectedLabelSize.width + trailingBuffer + leadingBuffer) - bounds.size.width
                // Enforce text alignment for this type
                sublabel.textAlignment = NSTextAlignment.right
            }
            // Set frame and text
            sublabel.frame = homeLabelFrame
            
            // Remove any replication
            repliLayer?.instanceCount = 1
            
            if (type == .leftRight || type == .rightLeft) {
                sequence = scrollSequence ?? [
                    ScrollStep(timeStep: 0.0, position: .home, edgeFades: .trailing),               // Starting point, at home, with trailing fade
                    ScrollStep(timeStep: animationDelay, position: .home, edgeFades: .trailing),    // Delay at home, maintaining fade state
                    FadeStep(timeStep: 0.2, edgeFades: [.leading, .trailing]),                      // 0.2 sec after delay ends, fade leading edge in as well
                    FadeStep(timeStep: -0.2, edgeFades: [.leading, .trailing]),                     // Maintain fade state until 0.2 sec before reaching away position
                    ScrollStep(timeStep: animationDuration, timingFunction: animationCurve,         // Away position, using animationCurve transition, with only leading edge faded in
                        position: .away, edgeFades: .leading),
                    ScrollStep(timeStep: animationDelay, position: .away, edgeFades: .leading),     // Delay at away, maintaining fade state (leading only)
                    FadeStep(timeStep: 0.2, edgeFades: [.leading, .trailing]),                      // 0.2 sec after delay ends, fade trailing edge back in as well
                    FadeStep(timeStep: -0.2, edgeFades: [.leading, .trailing]),                     // Maintain fade state until 0.2 sec before reaching home position
                    ScrollStep(timeStep: animationDuration, timingFunction: animationCurve,         // Ending point, back at home, with only trailing fade
                        position: .home, edgeFades: .trailing)
                ]
            } else { // .left or .right
                sequence = scrollSequence ?? [
                    ScrollStep(timeStep: 0.0, position: .home, edgeFades: .trailing),               // Starting point, at home, with trailing fade
                    ScrollStep(timeStep: animationDelay, position: .home, edgeFades: .trailing),    // Delay at home, maintaining fade state
                    FadeStep(timeStep: 0.2, edgeFades: [.leading, .trailing]),                      // 0.2 sec after delay ends, fade leading edge in as well
                    FadeStep(timeStep: -0.2, edgeFades: [.leading, .trailing]),                     // Maintain fade state until 0.2 sec before reaching away position
                    ScrollStep(timeStep: animationDuration, timingFunction: animationCurve,         // Away position, using animationCurve transition, with only leading edge faded in
                        position: .away, edgeFades: .leading),
                    ScrollStep(timeStep: animationDelay, position: .away, edgeFades: .leading),     // "Delay" at away, maintaining fade state
                ]
            }
        }
        
        
        
        // Configure gradient for current condition
        applyGradientMask(fadeLength, animated: !self.labelize)
        
        if !tapToScroll && !holdScrolling && shouldBeginScroll {
            beginScroll(sequence)
        }
    }
    
    private func sublabelSize() -> CGSize {
        // Bound the expected size
        let maximumLabelSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        // Calculate the expected size
        var expectedLabelSize = sublabel.sizeThatFits(maximumLabelSize)
        
        #if os(tvOS)
            // Sanitize width to 16384.0 (largest width a UILabel will draw on tvOS)
            expectedLabelSize.width = min(expectedLabelSize.width, 16384.0)
        #else
            // Sanitize width to 5461.0 (largest width a UILabel will draw on an iPhone 6S Plus)
            expectedLabelSize.width = min(expectedLabelSize.width, 5461.0)
        #endif

        // Adjust to own height (make text baseline match normal label)
        expectedLabelSize.height = bounds.size.height
        return expectedLabelSize
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var fitSize = sublabel.sizeThatFits(size)
        fitSize.width += leadingBuffer
        return fitSize
    }
    
    //
    // MARK: - Animation Handling
    //
    
    open func labelShouldScroll() -> Bool {
        // Check for nil string
        if sublabel.text == nil {
            return false
        }
        
        // Check for empty string
        if sublabel.text!.isEmpty {
            return false
        }
        
        // Check if the label string fits
        let labelTooLarge = (sublabelSize().width + leadingBuffer) > self.bounds.size.width + CGFloat.ulpOfOne
        let animationHasDuration = speed.value > 0.0
        return (!labelize && labelTooLarge && animationHasDuration)
    }
    
    private func labelReadyForScroll() -> Bool {
        // Check if we have a superview
        if superview == nil {
            return false
        }
        
        // Check if we are attached to a window
        if window == nil {
            return false
        }
        
        // Check if our view controller is ready
        let viewController = firstAvailableViewController()
        if viewController != nil {
            if !viewController!.isViewLoaded {
                return false
            }
        }
        
        return true
    }
    
    private func returnLabelToHome() {
        // Remove any gradient animation
        maskLayer?.removeAllAnimations()
        
        // Remove all sublabel position animations
        sublabel.layer.removeAllAnimations()
        
        // Remove completion block
        scrollCompletionBlock = nil
    }
    
    private func beginScroll(_ sequence: [MarqueeStep]) {
        let scroller = generateScrollAnimation(sequence)
        let fader = generateGradientAnimation(sequence, totalDuration: scroller.duration)
        
        scroll(scroller, fader: fader)
    }
    
    private func scroll(_ scroller: MLAnimation, fader: MLAnimation?) {
        // Check for conditions which would prevent scrolling
        if !labelReadyForScroll() {
            return
        }
        // Convert fader to var
        var fader = fader
        
        // Call pre-animation hook
        labelWillBeginScroll()
        
        // Start animation transactions
        CATransaction.begin()
        CATransaction.setAnimationDuration(TimeInterval(scroller.duration))
        
        // Create gradient animation, if needed
        let gradientAnimation: CAKeyframeAnimation?
        // Check for IBDesignable
        #if !TARGET_INTERFACE_BUILDER
            if fadeLength > 0.0 {
                // Remove any setup animation, but apply final values
                if let setupAnim = maskLayer?.animation(forKey: "setupFade") as? CABasicAnimation, let finalColors = setupAnim.toValue as? [CGColor] {
                    maskLayer?.colors = finalColors
                }
                maskLayer?.removeAnimation(forKey: "setupFade")
                
                // Generate animation if needed
                if let previousAnimation = fader?.anim {
                    gradientAnimation = previousAnimation
                } else {
                    gradientAnimation = nil
                }
                
                // Apply fade animation
                maskLayer?.add(gradientAnimation!, forKey: "gradient")
            } else {
                // No animation needed
                fader = nil
            }
        #else
            fader = nil;
        #endif
        
        scrollCompletionBlock = { [weak self] (finished: Bool) -> () in
            guard (self != nil) else {
                return
            }
            
            // Call returned home function
            self!.labelReturnedToHome(true)
            
            // Check to ensure that:
            
            // 1) The instance is still attached to a window - this completion block is called for
            //    many reasons, including if the animation is removed due to the view being removed
            //    from the UIWindow (typically when the view controller is no longer the "top" view)
            guard self!.window != nil else {
                return
            }
            // 2) We don't double fire if an animation already exists
            guard self!.sublabel.layer.animation(forKey: "position") == nil else {
                return
            }
            // 3) We don't not start automatically if the animation was unexpectedly interrupted
            guard finished else {
                // Do not continue into the next loop
                return
            }
            // 4) A completion block still exists for the NEXT loop. A notable case here is if
            // returnLabelToHome() was called during a subclass's labelReturnToHome() function
            guard (self!.scrollCompletionBlock != nil) else {
                return
            }
            
            // Begin again, if conditions met
            if (self!.labelShouldScroll() && !self!.tapToScroll && !self!.holdScrolling) {
                // Perform completion callback
                self!.scroll(scroller, fader: fader)
            }
        }
        
        // Perform scroll animation
        scroller.anim.setValue(true, forKey: MarqueeKeys.CompletionClosure.rawValue)
        scroller.anim.delegate = self
        if type == .left || type == .right {
            // Make it stay at away permanently
            scroller.anim.isRemovedOnCompletion = false
            scroller.anim.fillMode = kCAFillModeForwards
        }
        sublabel.layer.add(scroller.anim, forKey: "position")
        
        CATransaction.commit()
    }
    
    private func generateScrollAnimation(_ sequence: [MarqueeStep]) -> MLAnimation {
        // Create scroller, which defines the animation to perform
        let homeOrigin = homeLabelFrame.origin
        let awayOrigin = offsetCGPoint(homeLabelFrame.origin, offset: awayOffset)
        
        let scrollSteps = sequence.filter({ $0 is ScrollStep }) as! [ScrollStep]
        let totalDuration = scrollSteps.reduce(0.0) { $0 + $1.timeStep }
        
        // Build scroll data
        var totalTime: CGFloat = 0.0
        var scrollKeyTimes = [NSNumber]()
        var scrollKeyValues = [NSValue]()
        var scrollTimingFunctions = [CAMediaTimingFunction]()
        
        for (offset, step) in scrollSteps.enumerated() {
            // Scroll Times
            totalTime += step.timeStep
            scrollKeyTimes.append(NSNumber(value:Float(totalTime/totalDuration)))
            
            // Scroll Values
            let scrollPosition: CGPoint
            switch step.position {
            case .home:
                scrollPosition = homeOrigin
            case .away:
                scrollPosition = awayOrigin
            case .partial(let frac):
                scrollPosition = offsetCGPoint(homeOrigin, offset: awayOffset*frac)
            }
            scrollKeyValues.append(NSValue(cgPoint:scrollPosition))
            
            // Scroll Timing Functions
            // Only need n-1 timing functions, so discard the first value as it's unused
            if offset == 0 { continue }
            scrollTimingFunctions.append(timingFunctionForAnimationCurve(step.timingFunction))
        }
        
        // Create animation
        let animation = CAKeyframeAnimation(keyPath: "position")
        // Set values
        animation.keyTimes