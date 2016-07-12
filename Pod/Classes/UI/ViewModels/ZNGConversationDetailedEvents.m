//
//  ZNGConversationDetailedEvents.m
//  Pods
//
//  Created by Jason Neel on 7/12/16.
//
//

#import "ZNGConversationDetailedEvents.h"

@implementation ZNGConversationDetailedEvents

- (BOOL) isEqual:(ZNGConversationDetailedEvents *)other
{
    if (![other isKindOfClass:[ZNGConversationDetailedEvents class]]) {
        return NO;
    }
    
    return [super isEqual:other];
}

- (NSUInteger) hash
{
    return [super hash] >> 1;
}

- (NSArray<NSString *> *) eventTypes
{
    // No specific filter == all event types
    return nil;
}

@end
