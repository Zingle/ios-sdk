//
//  ZNGUser+TypingIndicatorData.m
//  Pods
//
//  Created by Jason Neel on 8/30/17.
//
//

#import "ZNGUser+TypingIndicatorData.h"

@implementation ZNGUser (TypingIndicatorData)

- (NSString *)senderId
{
    return self.userId;
}

- (NSString *)senderDisplayName
{
    return [self fullName];
}

- (NSDate *)date
{
    // There is no meaningful date, but JSQMessages insists on a non null
    return [NSDate date];
}

- (BOOL)isMediaMessage
{
    return NO;
}

- (NSUInteger)messageHash
{
    return [self.userId hash];
}

- (BOOL) isTypingIndicator
{
    return YES;
}

- (NSString *) text
{
    return [NSString stringWithFormat:@"%@ is responding", [self senderDisplayName]];
}

@end
