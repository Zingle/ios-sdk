//
//  ZNGNewService.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGNewService.h"

@implementation ZNGNewService

- (id)initWithService:(ZNGService*)service
{
    self = [super init];
    
    if (self) {
        _accountId = service.account.accountId;
        _displayName = service.displayName;
        _businessName = service.businessName;
        _timeZone = service.timeZone;
        _planCode = service.plan.code;
        _serviceAddress = service.serviceAddress;
    }
    
    return self;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"accountId" : @"account_id",
             @"displayName" : @"display_name",
             @"businessName" : @"business_name",
             @"timeZone" : @"time_zone",
             @"planCode" : @"plan_code",
             @"serviceAddress" : @"service_address",
             };
}

+ (NSValueTransformer*)serviceAddressJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[ZNGServiceAddress class]];
}

@end
