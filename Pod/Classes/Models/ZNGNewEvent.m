//
//  ZNGNewEvent.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGNewEvent.h"

@implementation ZNGNewEvent

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"eventType" : @"event_type",
             @"contactId" : @"contact_id",
             @"body" : @"body"
             };
}

@end
