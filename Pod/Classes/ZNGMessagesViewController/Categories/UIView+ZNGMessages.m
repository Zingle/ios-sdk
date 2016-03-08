
//

#import "UIView+ZNGMessages.h"

@implementation UIView (ZNGMessages)

- (void)zng_pinSubview:(UIView *)subview toEdge:(NSLayoutAttribute)attribute
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:attribute
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:subview
                                                     attribute:attribute
                                                    multiplier:1.0f
                                                      constant:0.0f]];
}

- (void)zng_pinAllEdgesOfSubview:(UIView *)subview
{
    [self zng_pinSubview:subview toEdge:NSLayoutAttributeBottom];
    [self zng_pinSubview:subview toEdge:NSLayoutAttributeTop];
    [self zng_pinSubview:subview toEdge:NSLayoutAttributeLeading];
    [self zng_pinSubview:subview toEdge:NSLayoutAttributeTrailing];
}

@end
