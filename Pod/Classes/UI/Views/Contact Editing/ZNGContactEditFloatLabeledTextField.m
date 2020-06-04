//
//  ZNGContactEditFloatLabeledTextField.m
//  Pods
//
//  Created by Jason Neel on 8/30/16.
//
//

#import "ZNGContactEditFloatLabeledTextField.h"

@interface ZNGContactEditFloatLabeledTextField ()
@property (nonatomic, weak, nullable) id zng_originalProvider;
@end

@implementation ZNGContactEditFloatLabeledTextField

@synthesize zng_originalProvider;

- (CGRect) rightViewRectForBounds:(CGRect)bounds
{
    // We will make our view square with both dimensions set to half our height
    CGFloat halfHeight = self.bounds.size.height / 2.0;
    CGFloat quarterHeight = halfHeight / 2.0;

    CGPoint rightViewCenter = CGPointMake(self.bounds.size.width - quarterHeight, halfHeight);
    
    return CGRectMake(rightViewCenter.x - quarterHeight, rightViewCenter.y - quarterHeight, halfHeight, halfHeight);
}

@end
