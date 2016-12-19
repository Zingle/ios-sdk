//
//  ZNGTemplate.m
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import "ZNGTemplate.h"

static NSString * const ResponseTimeMagicString = @"{response_time}";

NSString * const ZNGTemplateTypeAutomatedWelcome = @"automated_welcome";
NSString * const ZNGTemplateTypeWelcome = @"welcome";
NSString * const ZNGTemplateTypeGeneral = @"general";

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
    return [[self.body lowercaseString] containsString:ResponseTimeMagicString];
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
    
    NSRegularExpression * responseTimeRegex = [NSRegularExpression regularExpressionWithPattern:@"\\{response_time\\}" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableString * mutableBody = [self.body mutableCopy];
    NSArray<NSTextCheckingResult *> * matches;
    
    do {
        matches = [responseTimeRegex matchesInString:mutableBody options:0 range:NSMakeRange(0, [mutableBody length])];
        NSTextCheckingResult * firstMatch = [matches firstObject];
        
        if (firstMatch != nil) {
            NSRange matchRange = firstMatch.range;
            [mutableBody replaceCharactersInRange:matchRange withString:responseTimeString];
        }
    } while ([matches count] > 0);
    
    return mutableBody;
}

@end
