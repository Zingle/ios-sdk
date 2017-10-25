//
//  ZNGPendingResponseOrNote.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/24/17.
//

#import "ZNGPendingResponseOrNote.h"
#import "ZNGUser.h"

NSString * const ZNGPendingResponseTypeMessage = @"message";
NSString * const ZNGPendingResponseTypeInternalNote = @"note";

@implementation ZNGPendingResponseOrNote

- (id _Nonnull) initWithUser:(ZNGUser * _Nonnull)user eventType:(NSString * _Nonnull)eventType
{
    self = [super init];
    
    if (self != nil) {
        self.user = user;
        self.eventType = eventType;
    }
    
    return self;
}

- (NSUInteger) hash
{
    return [self.user hash];
}

- (BOOL) isEqual:(ZNGPendingResponseOrNote *)object
{
    if (![object isKindOfClass:[ZNGPendingResponseOrNote class]]) {
        return NO;
    }
    
    return [self.user isEqual:object.user];
}

#pragma mark - JSQMessageData
- (NSString *)senderId
{
    return self.user.userId;
}

- (NSString *)senderDisplayName
{
    return [self.user fullName];
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
    return [self.user.userId hash];
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
