//
//  GradientLoadingView.swift
//  Zingle
//
//  Created by Jason Neel on 8/3/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

import UIKit

let animationKey = "movingGradientAnimation"

let colorLocations = [-1.0, -0.8, -0.2, 0.0, 0.2, 0.8, 1.0]


@IBDesignable
@objc public class GradientLoadingView: UIView {
    
    private var animating: Bool = false
    
    @IBInspectable public var hidesWhenStopped: Bool = false {
        didSet {
            if hidesWhenStopped && !animating {
                hidden = true
            }
        }
    }
    
    /**
     *  The center color of the animated gradient marked by X:  Y----X----Y
     */
    @IBInspectable public var centerColor: UIColor = UIColor.clearColor() {
        didSet {
            setupGradientLayer()
        }
    }
    
    /**
     * The edge color of the animated gradient marked by Y:  Y---X---Y
     */
    @IBInspectable public var edgeColor: UIColor = UIColor.clearColor() {
        didSet {
            setupGradientLayer()
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupGradientLayer()
    }
    
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupGradientLayer()
    }
    
    override public class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    public func startAnimating() {
        
        if animating {
            return
        }
        
        layer.removeAnimationForKey(animationKey)
        
        let animation = CABasicAnimation.init(keyPath: "locations")
        animation.fromValue = colorLocations
        animation.toValue = colorLocations.map({ $0 + 1.0 })
        animation.repeatCount = Float.infinity
        animation.duration = 1.0
        layer.addAnimation(animation, forKey: animationKey)
        animating = true
        
        hidden = false
    }
    
    public func stopAnimating() {
        
        if !animating {
            return
        }
        
        animating = false
        layer.removeAnimationForKey(animationKey)
     
        if hidesWhenStopped {
            hidden = true
        }
    }
    
    private func setupGradientLayer() {
        guard let layer = layer as? CAGradientLayer else {
            return
        }
        
        layer.startPoint = CGPointMake(0.0, 0.5)
        layer.endPoint = CGPointMake(1.0, 0.5)
        let edgeCGColor = edgeColor.CGColor
        let centerCGColor = centerColor.CGColor
        layer.colors = [centerCGColor, edgeCGColor, edgeCGColor, centerCGColor, edgeCGColor, edgeCGColor, centerCGColor]
        layer.locations = colorLocations
    }
}
