//
//  ZNGConversationTimestampFormatter.m
//  Pods
//
//  Created by Jason Neel on 8/11/16.
//
//

#import "ZNGConversationTimestampFormatter.h"

@implementation ZNGConversationTimestampFormatter

+ (JSQMessagesTimestampFormatter *)sharedFormatter
{
    static JSQMessagesTimestampFormatter *_sharedFormatter = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        _sharedFormatter = [[ZNGConversationTimestampFormatter alloc] init];
    });
    
    return _sharedFormatter;
}

- (instancetype) init
{
    self = [super init];
    
    if (self != nil) {
        UIColor *color = [UIColor lightGrayColor];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        self.dateTextAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0f],
                                 NSForegroundColorAttributeName : color,
                                 NSParagraphStyleAttributeName : paragraphStyle };
        
        self.timeTextAttributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:14.0f],
                                 NSForegroundColorAttributeName : color,
                                 NSParagraphStyleAttributeName : paragraphStyle };
    }
    
    return self;
}

@end
