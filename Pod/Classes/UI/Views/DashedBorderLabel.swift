//
//  DashedBorderLabel.swift
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

import UIKit

@objc @IBDesignable
public class DashedBorderLabel: UILabel {
    
    var borderLine: CAShapeLayer?
    
    @IBInspectable public var borderColor: UIColor? {
        didSet {
            drawBorder()
        }
    }
    
    @IBInspectable public var borderWidth: CGFloat = 0.0 {
        didSet {
            drawBorder()
        }
    }
    
    @IBInspectable public var textInset: CGFloat = 0.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set (newCornerRadius) {
            layer.cornerRadius = newCornerRadius
            drawBorder()
        }
    }

    public override func awakeFromNib() {
        drawBorder()
    }
    
    func drawBorder() {
        borderLine?.removeFromSuperlayer()
        
        layer.masksToBounds = borderWidth > 0
        
        let border = CAShapeLayer()
        border.strokeColor = borderColor?.CGColor
        border.fillColor = nil
        border.lineWidth = borderWidth
        border.lineDashPattern = [4,4]
        borderLine = border
        layer.addSublayer(border)
    }
    
    public override func layoutSubviews() {
        borderLine?.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).CGPath
        borderLine?.frame = bounds
    }
    
    public override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insets = UIEdgeInsets(top: textInset, left: textInset, bottom: textInset, right: textInset)
        let insetRect = UIEdgeInsetsInsetRect(bounds, insets)
        let textRect = super.textRectForBounds(insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right)
        return UIEdgeInsetsInsetRect(textRect, invertedInsets)
    }
    
    public override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: textInset, left: textInset, bottom: textInset, right: textInset)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}
