//
//  ZNGLabelGridView.m
//  Pods
//
//  Created by Jason Neel on 10/18/16.
//
//

#import "ZNGLabelGridView.h"
#import "ZNGDashedBorderLabel.h"
#import "ZNGLabel.h"
#import "ZNGContactGroup.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"

@import SBObjectiveCWrapper;

@implementation ZNGLabelGridView
{
    UIImage * xImage;
    UIColor * moreButtonColor;
    
    CGSize totalSize;
    
    ZNGDashedBorderLabel * addLabelView;
    NSArray<ZNGDashedBorderLabel *> * labelViews;
    UILabel * moreLabel;
}

#pragma mark - Initialization
- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    totalSize = CGSizeZero;
    
    // Defaults
    _horizontalSpacing = 6.0;
    _verticalSpacing = 6.0;
    _font = [UIFont latoFontOfSize:13.0];
    _labelBorderWidth = 2.0;
    _labelTextInset = 6.0;
    _labelCornerRadius = 14.0;
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGLabelGridView class]];
    xImage = [UIImage imageNamed:@"deleteX" inBundle:bundle compatibleWithTraitCollection:nil];
    moreButtonColor = [UIColor colorNamed:@"ZNGToolbarButton" inBundle:bundle compatibleWithTraitCollection:nil];
    self.userInteractionEnabled = NO;
    
    _labelIcon = [[UIImage imageNamed:@"smallTag" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _groupIcon = [[UIImage imageNamed:@"smallStalker" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - Setters
- (void) setDelegate:(id<ZNGLabelGridViewDelegate>)delegate
{
    _delegate = delegate;
    self.userInteractionEnabled = (delegate != nil);
}

- (void) setShowAddLabel:(BOOL)showAddLabel
{
    _showAddLabel = showAddLabel;
    [self createLabelViews];
}

- (void) setShowRemovalX:(BOOL)showRemovalX
{
    _showRemovalX = showRemovalX;
    [self createLabelViews];
}

- (void) setLabels:(NSArray<ZNGLabel *> *)labels
{
    _labels = labels;
    [self createLabelViews];
}

- (void) setGroups:(NSArray<ZNGContactGroup *> *)groups
{
    _groups = groups;
    [self createLabelViews];
}

- (void) setLabelIcon:(UIImage *)labelIcon
{
    _labelIcon = labelIcon;
    [self createLabelViews];
}

- (void) setGroupIcon:(UIImage *)groupIcon
{
    _groupIcon = groupIcon;
    [self createLabelViews];
}

- (void) setMaxRows:(NSUInteger)maxRows
{
    _maxRows = maxRows;
    [self createLabelViews];
}

- (void) setHorizontalSpacing:(CGFloat)horizontalSpacing
{
    _horizontalSpacing = horizontalSpacing;
    [self invalidateIntrinsicContentSize];
}

- (void) setVerticalSpacing:(CGFloat)verticalSpacing
{
    _verticalSpacing = verticalSpacing;
    [self invalidateIntrinsicContentSize];
}

- (void) setFont:(UIFont *)font
{
    _font = font;
    [self createLabelViews];
}

- (void) setLabelBorderWidth:(CGFloat)labelBorderWidth
{
    _labelBorderWidth = labelBorderWidth;
    [self createLabelViews];
}

- (void) setLabelTextInset:(CGFloat)labelTextInset
{
    _labelTextInset = labelTextInset;
    [self createLabelViews];
}

- (void) setLabelCornerRadius:(CGFloat)labelCornerRadius
{
    _labelCornerRadius = labelCornerRadius;
    [self createLabelViews];
}

#pragma mark - Touching
- (void) pressedAddLabel:(UITapGestureRecognizer *)tapper
{
    [self.delegate labelGridPressedAddLabel:self];
}

- (void) tappedLabel:(UITapGestureRecognizer *)tapper
{
    if (![tapper.view isKindOfClass:[ZNGDashedBorderLabel class]]) {
        return;
    }
    
    ZNGDashedBorderLabel * labelView = (ZNGDashedBorderLabel *)tapper.view;
    NSUInteger index = [labelViews indexOfObject:labelView];
    
    if ((index != NSNotFound) && (index < [self.labels count])) {
        ZNGLabel * label = self.labels[index];
        [self.delegate labelGrid:self pressedRemoveLabel:label];
    }
}

#pragma mark - Label setup

- (void) configureLabel:(ZNGDashedBorderLabel *)label
{
    label.borderWidth = self.labelBorderWidth;
    label.textInset = self.labelTextInset;
    label.cornerRadius = self.labelCornerRadius;
    label.font = self.font;
    label.userInteractionEnabled = YES;
}

- (void) createLabelViews
{
    NSMutableArray<ZNGDashedBorderLabel *> * newLabelViews = [[NSMutableArray alloc] initWithCapacity:[self.labels count]];
    
    if (self.showAddLabel) {
        if (addLabelView.superview == nil) {
            // Create the add label view
            addLabelView = [[ZNGDashedBorderLabel alloc] init];
            [self configureLabel:addLabelView];
            addLabelView.dashed = YES;
            addLabelView.text = @" ADD TAG ";
            addLabelView.textColor = [UIColor grayColor];
            addLabelView.backgroundColor = [UIColor clearColor];
            addLabelView.borderColor = [UIColor grayColor];
            
            UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedAddLabel:)];
            [addLabelView addGestureRecognizer:tapper];
            
            [self addSubview:addLabelView];
        }
    } else {
        [addLabelView removeFromSuperview];
        addLabelView = nil;
    }
    
    for (ZNGLabel * label in self.labels) {
        ZNGDashedBorderLabel * labelView = [[ZNGDashedBorderLabel alloc] init];
        [self configureLabel:labelView];
        labelView.text = label.displayName;
        
        NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:@" "];
        
        if (self.labelIcon != nil) {
            NSTextAttachment * iconAttachment = [[NSTextAttachment alloc] init];
            iconAttachment.image = self.labelIcon;
            
            // For < 10 pt fonts, we need to adjust the label icon down a bit farther.  There is assuredly a more intelligent logic
            //  to this than adding 2.0 for small fonts, but this manual adjustment gets the job done.
            // This probably has a lot to do with image size vs. font point size.
            CGFloat imageDescender = (self.font.pointSize > 10.0) ? self.font.descender : self.font.descender - 2.0;
            iconAttachment.bounds = CGRectMake(0.0, imageDescender, self.labelIcon.size.width, self.labelIcon.size.height);
            NSAttributedString * iconString = [NSAttributedString attributedStringWithAttachment:iconAttachment];
            
            [text appendAttributedString:iconString];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
        }
        
        NSAttributedString * labelAttributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", [label.displayName uppercaseString] ?: @""]];
        [text appendAttributedString:labelAttributedText];

        if (self.showRemovalX) {
            NSTextAttachment * imageAttachment = [[NSTextAttachment alloc] init];
            imageAttachment.image = xImage;
            imageAttachment.bounds = CGRectMake(0.0, 0.5, xImage.size.width, xImage.size.height);
            
            NSAttributedString * imageAsText = [NSAttributedString attributedStringWithAttachment:imageAttachment];
            
            NSAttributedString * oneSpaceString = [[NSAttributedString alloc] initWithString:@" "];
            [text appendAttributedString:oneSpaceString];
            [text appendAttributedString:imageAsText];
            [text appendAttributedString:oneSpaceString];
        }
        
        UIColor * textColor = [label textUIColor];
        labelView.font = self.font;
        labelView.textColor = textColor;
        labelView.borderColor = textColor;
        labelView.backgroundColor = [label backgroundUIColor];
        [text addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, [text length])];
        labelView.attributedText = text;
        
        UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedLabel:)];
        [labelView addGestureRecognizer:tapper];
        
        [newLabelViews addObject:labelView];
        [self addSubview:labelView];
    }
    
    for (ZNGContactGroup * group in self.groups) {
        ZNGDashedBorderLabel * groupView = [[ZNGDashedBorderLabel alloc] init];
        [self configureLabel:groupView];
        groupView.text = group.displayName;
        
        NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:@" "];
        
        if (self.groupIcon != nil) {
            NSTextAttachment * iconAttachment = [[NSTextAttachment alloc] init];
            iconAttachment.image = self.groupIcon;
            
            // For < 10 pt fonts, we need to adjust the label icon down a bit farther.  There is assuredly a more intelligent logic
            //  to this than adding 2.0 for small fonts, but this manual adjustment gets the job done.
            // This probably has a lot to do with image size vs. font point size.
            CGFloat imageDescender = (self.font.pointSize > 10.0) ? self.font.descender : self.font.descender - 2.0;
            iconAttachment.bounds = CGRectMake(0.0, imageDescender, self.groupIcon.size.width, self.groupIcon.size.height);
            NSAttributedString * iconString = [NSAttributedString attributedStringWithAttachment:iconAttachment];
            
            [text appendAttributedString:iconString];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
        }
        
        NSAttributedString * labelAttributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", [group.displayName uppercaseString] ?: @""]];
        [text appendAttributedString:labelAttributedText];
        
        UIColor * textColor = group.textColor;
        groupView.font = self.font;
        groupView.textColor = textColor;
        groupView.borderColor = textColor;
        groupView.backgroundColor = group.backgroundColor;
        
        if (textColor != nil) {
            [text addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, [text length])];
        }
        
        groupView.attributedText = text;
        
        [newLabelViews addObject:groupView];
        [self addSubview:groupView];
    }
    
    if ((self.maxRows > 0) && (moreLabel == nil)) {
        moreLabel = [[UILabel alloc] init];
    }
    
    SBLogDebug(@"Replacing %llu existing labels with %llu labels.", (unsigned long long)[labelViews count], (unsigned long long)[newLabelViews count]);
    
    for (ZNGDashedBorderLabel * label in labelViews) {
        [label removeFromSuperview];
    }
    
    labelViews = newLabelViews;
    
    SBLogDebug(@"%@ now has %llu subviews", [self class], (unsigned long long)[self.subviews count]);
    
    [self layoutIfNeeded];
}

- (void) layoutSubviews
{
    // Note that this method assumes that all labels are identical height
    CGFloat currentX = 0.0;
    CGFloat currentY = 0.0;
    CGFloat widestWidth = 0.0;
    NSUInteger rowIndex = 0;
    NSUInteger overflowCount = 0;
    UILabel * lastDisplayedLabel = nil;
    
    if (addLabelView != nil) {
        CGSize addLabelSize = [addLabelView intrinsicContentSize];
        addLabelView.frame = CGRectMake(0.0, 0.0, addLabelSize.width, addLabelSize.height);
        lastDisplayedLabel = addLabelView;
        currentY = currentY + addLabelSize.height + self.verticalSpacing;
    }
    
    for (ZNGDashedBorderLabel * label in labelViews) {
        CGSize labelSize = [label intrinsicContentSize];
        
        // If we've already overflowed, we will not even check for remaining space; this label will already be skipped.
        if ((currentX != 0) && (overflowCount == 0)) {
            // Do we need to go down to the next row?
            CGFloat remainingWidth = self.frame.size.width - currentX;
            
            if (remainingWidth < labelSize.width) {
                // We need to go to the next row
                rowIndex++;
                
                // .. but are we allowed to?
                if ((self.maxRows == 0) || (rowIndex < self.maxRows)) {
                    currentY += labelSize.height + self.verticalSpacing;
                    rowIndex++;
                    currentX = 0.0;
                } else {
                    NSUInteger currentIndex = [labelViews indexOfObject:label];
                    overflowCount = [labelViews count] - currentIndex;
                }
            }
        }
        
        if (overflowCount == 0) {
            label.frame = CGRectMake(currentX, currentY, labelSize.width, labelSize.height);
            
            if (label.superview == nil) {
                [self addSubview:label];
            }
            
            lastDisplayedLabel = label;
            currentX += labelSize.width + self.horizontalSpacing;
            
            if (currentX > widestWidth) {
                widestWidth = currentX;
            }
        } else {
            [label removeFromSuperview];
        }
    }
    
    if (overflowCount > 0) {
        // We cannot fit all of our labels within our bounds.  Add a "x more..." label and make room as necessary
        CGFloat biggerSize = self.font.pointSize + 5.0;
        moreLabel.font = [UIFont fontWithName:self.font.fontName size:biggerSize];
        moreLabel.textColor = moreButtonColor;
        moreLabel.backgroundColor = [UIColor clearColor];
        
        CGSize moreLabelSize = [moreLabel intrinsicContentSize];
        CGFloat downwardScooch = 0.0;
        
        if (lastDisplayedLabel != nil) {
            downwardScooch = lastDisplayedLabel.frame.size.height - moreLabelSize.height;
        }
        
        CGRect moreLabelFrame = CGRectMake(currentX + self.horizontalSpacing, currentY + downwardScooch, moreLabelSize.width, moreLabelSize.height);
        
        if (moreLabel.superview == nil) {
            [self addSubview:moreLabel];
        }
        
        // Loop through all labels on this same row, eliminating any that would push the "X more..." label off screen
        for (NSInteger i = [labelViews count]-1; i >= 0; i--) {
            ZNGDashedBorderLabel * label = labelViews[i];
            
            if (label.superview == nil) {
                continue;
            }
            
            CGFloat labelMinY = CGRectGetMinY(label.frame);
            CGFloat labelMaxY = CGRectGetMaxY(label.frame);
            CGFloat moreLabelMaxY = CGRectGetMaxY(moreLabel.frame);
            CGFloat moreLabelMinY = CGRectGetMinY(moreLabel.frame);
            
            if ((labelMinY > moreLabelMaxY) || (labelMaxY < moreLabelMinY)) {
                // Not in the same row
                continue;
            }
            
            CGFloat remainingRightSpace = self.bounds.size.width - CGRectGetMaxX(label.frame);
            
            if (remainingRightSpace < (moreLabelSize.width + self.horizontalSpacing)) {
                // This label would overlap our "X more..." label.  Move our "X more" label into its place and remove this label from the view hierarchy.
                moreLabelFrame = CGRectMake(label.frame.origin.x, moreLabelFrame.origin.y, moreLabelFrame.size.width, moreLabelFrame.size.height);
                [label removeFromSuperview];
                overflowCount++;
            }
        }
        
        currentX = moreLabelFrame.origin.x + moreLabelFrame.size.width + self.horizontalSpacing;
        
        if (currentX > widestWidth) {
            widestWidth = currentX;
        }
        
        moreLabel.text = [NSString stringWithFormat:@"%llu more...", (unsigned long long)overflowCount];
        moreLabel.frame = moreLabelFrame;
    } else {
        [moreLabel removeFromSuperview];
    }
    
    CGSize oldSize = totalSize;
    
    if (lastDisplayedLabel == nil) {
        totalSize = [super intrinsicContentSize];
    } else {
        totalSize = CGSizeMake(widestWidth - self.horizontalSpacing, lastDisplayedLabel.frame.origin.y + lastDisplayedLabel.frame.size.height);
    }
    
    if (!CGSizeEqualToSize(oldSize, totalSize)) {
        [self invalidateIntrinsicContentSize];
    }
}

#pragma mark - Sizing
- (CGSize) intrinsicContentSize
{
    if (CGSizeEqualToSize(totalSize, CGSizeZero)) {
        return [super intrinsicContentSize];
    }
    
    return totalSize;
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    if (CGSizeEqualToSize(totalSize, CGSizeZero)) {
        return [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    }
    
    return totalSize;
}

@end
