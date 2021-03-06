//
//  ZNGLabelGridView.h
//  Pods
//
//  Created by Jason Neel on 10/18/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGLabel;
@class ZNGContactGroup;
@class ZNGLabelGridView;

NS_ASSUME_NONNULL_BEGIN

@protocol ZNGLabelGridViewDelegate <NSObject>

- (void) labelGridPressedAddLabel:(ZNGLabelGridView *)grid;
- (void) labelGrid:(ZNGLabelGridView *)grid pressedRemoveLabel:(ZNGLabel *)label;

@end


@interface ZNGLabelGridView : UIView

@property (nonatomic, weak, nullable) id<ZNGLabelGridViewDelegate> delegate;

@property (nonatomic, assign) IBInspectable BOOL showAddLabel;
@property (nonatomic, assign) IBInspectable BOOL showRemovalX;

@property (nonatomic, strong, nullable) NSArray<ZNGLabel *> * labels;
@property (nonatomic, strong, nullable) NSArray<ZNGContactGroup *> * groups;

/**
 *  An optional icon to display before each label name.  Defaults to a tag icon.
 */
@property (nonatomic, strong, nullable) UIImage * labelIcon;

/**
 *  An optional icon to display before each group name.  Defaults to a stalker person icon.
 */
@property (nonatomic, strong, nullable) UIImage * groupIcon;

@property (nonatomic, assign) IBInspectable NSUInteger maxRows;
@property (nonatomic, assign) IBInspectable CGFloat horizontalSpacing;
@property (nonatomic, assign) IBInspectable CGFloat verticalSpacing;
@property (nonatomic, strong) IBInspectable UIFont * font;
@property (nonatomic, assign) IBInspectable CGFloat labelBorderWidth;
@property (nonatomic, assign) IBInspectable CGFloat labelTextInset;
@property (nonatomic, assign) IBInspectable CGFloat labelCornerRadius;


NS_ASSUME_NONNULL_END

@end
