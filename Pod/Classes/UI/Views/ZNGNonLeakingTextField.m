//
//  ZNGNonLeakingTextField.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/19/18.
//

#import "ZNGNonLeakingTextField.h"

@interface ZNGNonLeakingTextField ()
@property (nonatomic, weak, nullable) id zng_originalProvider;
@end

@implementation ZNGNonLeakingTextField

@synthesize zng_originalProvider;

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
