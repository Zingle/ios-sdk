//
//  ZNGTemplate.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGTemplate.h"

static NSString * const ResponseTimeMagicString = @"{response_time}";

@implementation ZNGTemplate

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"templateId" : @"id",
             @"displayName" : @"display_name",
             @"subject" : @"subject",
             @"type" : @"type",
             @"body" : @"body",
             @"isGlobal" : @"is_global"
             };
}

- (BOOL) requiresResponseTime
{
    return [self.body containsString:ResponseTimeMagicString];
}

- (NSArray<NSString *> *) responseTimeChoices
{
    return @[
             @"5 minutes",
             @"7 minutes",
             @"10 minutes",
             @"15 minutes",
             @"30 minutes"
             ];
}

- (NSString *) bodyWithResponseTime:(NSString *)responseTimeString
{
    if (responseTimeString == nil) {
        return self.body;
    }
    
    return [self.body stringByReplacingOccurrencesOfString:ResponseTimeMagicString withString:responseTimeString];
}

@end
