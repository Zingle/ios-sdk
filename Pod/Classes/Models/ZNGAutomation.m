//
//  ZNGAutomation.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGAutomation.h"

static NSString * const ZNGAutomationTypeEscalation = @"Escalation";
static NSString * const ZNGAutomationTypeKeyword = @"Keyword";
static NSString * const ZNGAutomationTypeSelfRegistration = @"Self-Registration";
static NSString * const ZNGAutomationTypeSurvey = @"Survey";
static NSString * const ZNGAutomationTypePhoneCall = @"Phone Call";
static NSString * const ZNGAutomationTypeCustom = @"Custom Automation";

@implementation ZNGAutomation

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return    @{
                @"automationId" : @"id",
                @"displayName" : @"display_name",
                @"type" : @"type",
                @"status" : @"status",
                @"isGlobal" : @"is_global"
                };
}

- (BOOL) canBeTriggedOnAContact
{
    NSArray<NSString *> * triggerableTypes = @[ZNGAutomationTypeSurvey, ZNGAutomationTypeSelfRegistration, ZNGAutomationTypeCustom];
    return [triggerableTypes containsObject:self.type];
}

- (BOOL) isActive
{
    return [self.status isEqualToString:@"active"];
}

@end
