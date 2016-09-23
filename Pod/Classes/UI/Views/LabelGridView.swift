//
//  LabelGridView.swift
//  Pods
//
//  Created by Jason Neel on 9/22/16.
//
//

import UIKit

@objc
public protocol LabelGridDelegate: AnyObject {
    func pressedAddLabel()
    func pressedRemoveLabel(label: ZNGLabel)
}

@objc
public class LabelGridView: UIView {
    
    public weak var delegate: LabelGridDelegate? = nil {
        didSet {
            userInteractionEnabled = (delegate != nil)
        }
    }
    
    @IBInspectable public var showAddLabel: Bool = false {
        didSet {
            createLabelViews()
        }
    }
    
    @IBInspectable public var showRemovalX: Bool = false {
        didSet {
            createLabelViews()
        }
    }

    public var labels: [ZNGLabel]? = nil {
        didSet {
            createLabelViews()
        }
    }
    
    @IBInspectable public var horizontalSpacing:CGFloat = 6.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable public var verticalSpacing:CGFloat = 6.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable public var font: UIFont = UIFont.latoFontOfSize(13.0) {
        didSet {
            createLabelViews()
        }
    }
    
    @IBInspectable public var labelBorderWidth:CGFloat = 2.0 {
        didSet {
            createLabelViews()
        }
    }
    
    @IBInspectable public var labelTextInset:CGFloat = 6.0 {
        didSet {
            createLabelViews()
        }
    }
    
    @IBInspectable public var labelCornerRadius:CGFloat = 12.0 {
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
        userInteractionEnabled = false
    }
    
    private func configureLabel(label: DashedBorderLabel) {
        label.borderWidth = labelBorderWidth
        label.textInset = labelTextInset
        label.cornerRadius = labelCornerRadius
        label.font = font
        label.userInteractionEnabled = true
    }
    
    @objc private func pressedAddLabel(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.pressedAddLabel()
    }
    
    @objc private func tappedLabel(gestureRecognizer: UITapGestureRecognizer) {
        if let tappedLabelView = gestureRecognizer.view as? DashedBorderLabel,
            index = labelViews?.indexOf(tappedLabelView),
            label = labels?[index] {
            delegate?.pressedRemoveLabel(label)
        }
    }
 
    private func createLabelViews() {
 
        var newLabelViews = [DashedBorderLabel]()
        
        if showAddLabel {
            if addLabelView?.superview == nil {
                // Create the add label view
                addLabelView = DashedBorderLabel()
                configureLabel(addLabelView!)
                addLabelView!.dashed = true
                addLabelView!.text = " ADD LABEL "
                addLabelView!.textColor = UIColor.grayColor()
                addLabelView!.backgroundColor = UIColor.clearColor()
                addLabelView!.borderColor = UIColor.grayColor()
                
                let tapper = UITapGestureRecognizer(target: self, action: #selector(pressedAddLabel))
                addLabelView!.addGestureRecognizer(tapper)
                
                addSubview(addLabelView!)
            }
        } else {
            addLabelView?.removeFromSuperview()
            addLabelView = nil
        }
        
        labels?.forEach({ (label: ZNGLabel) in
            let labelView = DashedBorderLabel()
            configureLabel(labelView)
            labelView.text = label.displayName
            
            let labelText = " \(label.displayName.uppercaseString) "
            let text = NSMutableAttributedString(string: labelText)
            
            if showRemovalX {
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = xImage
                imageAttachment.bounds = CGRectMake(0.0, 0.5, xImage.size.width, xImage.size.height)
                
                let imageAsText = NSAttributedString(attachment: imageAttachment)
                
                let oneSpaceString = NSAttributedString(string: " ")
                text.appendAttributedString(oneSpaceString)
                text.appendAttributedString(imageAsText)
                text.appendAttributedString(oneSpaceString)
            }
            
            let color = label.backgroundUIColor()
            labelView.font = font
            labelView.textColor = color
            labelView.borderColor = color
            labelView.backgroundColor = color.zng_colorByLighteningColor(0.5)
            text.addAttribute(NSForegroundColorAttributeName, value: color, range: NSMakeRange(0, text.length))
            labelView.attributedText = text
            
            let tapper = UITapGestureRecognizer(target: self, action: #selector(tappedLabel))
            labelView.addGestureRecognizer(tapper)
            
            newLabelViews.append(labelView)
            addSubview(labelView)
        })
        
        labelViews?.forEach {
            $0.removeFromSuperview()
        }
        
        labelViews = newLabelViews
        
        layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return totalSize ?? super.intrinsicContentSize()
    }
    
    public override func systemLayoutSizeFittingSize(targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return totalSize ?? super.systemLayoutSizeFittingSize(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
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
                    currentY = currentY + labelSize.height + verticalSpacing
                    currentX = 0.0
                }
            }
            
            label.frame = CGRectMake(currentX, currentY, labelSize.width, labelSize.height)
            currentX = currentX + labelSize.width + horizontalSpacing
            
            if currentX > widestWidth {
                widestWidth = currentX
            }
        })
        
        guard let lastFrame = labelViews?.last?.frame ?? addLabelView?.frame else {
            totalSize = super.intrinsicContentSize()
            return
        }
        
        totalSize = CGSizeMake(widestWidth - horizontalSpacing, lastFrame.origin.y + lastFrame.size.height)
    }
}
