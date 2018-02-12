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

// iOS 11.2 leaks every UITextField forever thanks to a circular reference in its internals.  I love Apple.
- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (@available(iOS 11.2, *)) {
        NSString *keyPath = @"textContentView.provider";
        @try {
            if (self.window) {
                id provider = [self valueForKeyPath:keyPath];
                
                if (!provider && self.zng_originalProvider) {
                    [self setValue:self.zng_originalProvider forKeyPath:keyPath];
                }
            } else {
                self.zng_originalProvider = [self valueForKeyPath:keyPath];
                [self setValue:nil forKeyPath:keyPath];
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
}

@end
