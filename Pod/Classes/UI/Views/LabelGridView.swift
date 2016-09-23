//
//  LabelGridView.swift
//  Pods
//
//  Created by Jason Neel on 9/22/16.
//
//

import UIKit

@objc
public class LabelGridView: UIView {
    
    public var showAddLabel: Bool = false {
        didSet {
            createLabelViews()
        }
    }

    public var labels: [ZNGLabel]? = nil {
        didSet {
            createLabelViews()
        }
    }
    
    public var horizontalSpacing:CGFloat = 4.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var verticalSpacing:CGFloat = 4.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var font: UIFont = UIFont.systemFontOfSize(13.0) {
        didSet {
            createLabelViews()
        }
    }
    
    var xImage: UIImage!
    
    private var totalSize:CGSize? = nil
    
    private var addLabelView: DashedBorderLabel? = nil
    
    private var labelViews: [DashedBorderLabel]? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let bundle = NSBundle(forClass: LabelGridView.self)
        xImage = UIImage(named: "deleteX", inBundle: bundle, compatibleWithTraitCollection: nil)?.imageWithRenderingMode(.AlwaysTemplate)
    }
 
    private func createLabelViews() {
 
        var newLabelViews = [DashedBorderLabel]()
        
        if showAddLabel {
            if addLabelView?.superview == nil {
                // Create the add label view
                addLabelView = DashedBorderLabel()
                addLabelView!.dashed = true
                addLabelView!.font = font
                addLabelView!.text = " ADD LABEL "
                addLabelView!.textColor = UIColor.grayColor()
                addLabelView!.backgroundColor = UIColor.clearColor()
                addLabelView!.borderColor = UIColor.grayColor()
                
                addSubview(addLabelView!)
            }
        } else {
            addLabelView?.removeFromSuperview()
            addLabelView = nil
        }
        
        labels?.forEach({ (label: ZNGLabel) in
            let labelView = DashedBorderLabel()
            labelView.text = label.displayName
            
            let labelText = " \(label.displayName.uppercaseString)  "
            let text = NSMutableAttributedString(string: labelText)
            
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = xImage
            imageAttachment.bounds = CGRectMake(0.0, 0.5, xImage.size.width, xImage.size.height)
            
            let imageAsText = NSAttributedString(attachment: imageAttachment)
            
            text.appendAttributedString(imageAsText)
            text.appendAttributedString(NSAttributedString(string: " "))
            
            let color = label.backgroundUIColor()
            labelView.font = font
            labelView.textColor = color
            labelView.borderColor = color
            labelView.backgroundColor = color.zng_colorByLighteningColor(0.5)
            text.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, text.length))
            labelView.attributedText = text
            
            newLabelViews.append(labelView)
            addSubview(labelView)
        })
        
        labelViews?.forEach {
            $0.removeFromSuperview()
        }
        
        labelViews = newLabelViews
        
        invalidateIntrinsicContentSize()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return totalSize ?? super.intrinsicContentSize()
    }
    
    public override func layoutSubviews() {
        // Note that this method assumes that all labels are identical height
        
        var currentX: CGFloat = 0.0
        var currentY: CGFloat = 0.0
        var widestWidth: CGFloat = 0.0
        
        if let addLabelView = addLabelView {
            let addLabelSize = addLabelView.intrinsicContentSize()
            addLabelView.frame = CGRectMake(0.0, 0.0, addLabelSize.width, addLabelSize.height)
            currentY = currentY + addLabelSize.height + verticalSpacing
        }
        
        labelViews?.forEach({ (label: DashedBorderLabel) in
            let labelSize = label.intrinsicContentSize()
            
            // Do we need to go down to the next row?
            if currentX != 0.0 {
                let remainingWidth = frame.size.width - currentX
                
                if remainingWidth < labelSize.width {
                    // We need to go to the next row
                    currentY = currentY + label.frame.size.height + verticalSpacing
                    currentX = 0.0
                }
            }
            
            label.frame = CGRectMake(currentX, currentY, labelSize.width, labelSize.height)
            currentX = currentX + labelSize.width + horizontalSpacing
            
            if currentX > widestWidth {
                widestWidth = currentX
            }
        })
        
        guard let lastFrame = labelViews?.last?.frame else {
            totalSize = super.intrinsicContentSize()
            return
        }
        
        totalSize = CGSizeMake(widestWidth, lastFrame.origin.y + lastFrame.size.height)
    }
}
