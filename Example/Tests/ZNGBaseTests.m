//
//  ZNGBaseTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/5/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import "ZNGBaseTests.h"
#import "ZingleSDK.h"

@implementation ZNGBaseTests

- (void)setUp
{
    [super setUp];
    NSString *key = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_KEY"];
    NSString *token = [[[NSProcessInfo processInfo] environment] objectForKey:@"TEST_TOKEN"];
    
    ZingleSDK *sdk = [ZingleSDK sharedSDK];
    [sdk setToken:token andKey:key forDebugMode:YES];
}

- (NSString *)accountId
{
    return @"11111111-1111-1111-1111-111111111114";
}

- (NSString *)planId
{
    return @"c77c7516-c14a-438f-b869-bf05f9e398bd";
}

- (NSString *)serviceId
{
    return @"22111111-1111-1111-1111-111111111111";
}

- (NSString *)timeZone
{
    return @"America/Los_Angeles";
}

- (NSString *)planCode
{
    return @"enterprise_lite";
}

- (ZNGServiceAddress *)serviceAddress
{
    ZNGServiceAddress *address = [[ZNGServiceAddress alloc] init];
    address.address     = @"Test Lane";
    address.city        = @"Test City";
    address.state       = @"IL";
    address.country     = @"US";
    address.postalCode  = @"60622";
    
    return address;
}

- (ZNGAccountPlan *)plan
{
    ZNGAccountPlan *plan = [[ZNGAccountPlan alloc] init];
    plan.planId = @"c77c7516-c14a-438f-b869-bf05f9e398bd";
    plan.code = @"sandbox";
    plan.monthlyOrUnitPrice = @0;
    plan.termMonths = @1;
    plan.setupPrice = @0;
    plan.displayName = @"Sandbox";
    plan.isPrinterPlan = false;
    
    return plan;
}

- (ZNGService *)service
{
    ZNGService *service = [[ZNGService alloc] init];
    service.account = [self account];
    service.displayName = @"Test Create Service";
    service.timeZone = [self timeZone];
    service.plan = [self plan];
    service.serviceAddress = [self serviceAddress];
    
    return service;
}

- (ZNGAccount *)account
{
    ZNGAccount *account = [[ZNGAccount alloc] init];
    account.accountId = @"11111111-1111-1111-1111-111111111114";
    
    return account;
}

- (NSString *)serviceChannelId
{
    return @"8c8b4e95-cf9f-4d08-b6ee-2f8cca2e69ec";
}

- (ZNGChannelType *)channelType
{
    ZNGChannelType *channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"0a293ea3-4721-433e-a031-610ebcf43255";
    
    return channelType;
}

- (NSString *)channelValue
{
    return @"+18585557777";
}

- (ZNGChannel *)serviceChannelWithValue:(NSString *)value
{
    ZNGChannel *serviceChannel = [[ZNGChannel alloc] init];
    serviceChannel.displayName = @"Test service channel";
    serviceChannel.value = value;
    serviceChannel.channelType = [self channelType];
    serviceChannel.country = @"US";
    serviceChannel.isDefaultForType = false;
    
    return serviceChannel;
}

- (ZNGNewChannel *)contactChannelWithValue:(NSString *)value
{
    ZNGChannel *contactChannel = [[ZNGChannel alloc] init];
    contactChannel.displayName = @"MOBILE";
    contactChannel.value = value;
    contactChannel.channelType = [self channelType];
    contactChannel.country = @"US";
    contactChannel.isDefaultForType = false;
    
    ZNGNewChannel *newChannel = [[ZNGNewChannel alloc] initWithChannel:contactChannel];
    
    return newChannel;
}

- (ZNGContact *)contact
{
    ZNGContact *contact = [[ZNGContact alloc] init];
    contact.isConfirmed = true;
    
    return contact;
}

- (NSString *)automationId
{
    return @"e1784f52-fef3-4107-b4cd-7b1077f930a1";
}

- (NSString *)labelId
{
    return @"d5a7bb87-6c55-4334-bece-952f70522fb5";
}

- (NSString *)contactId
{
    return @"e07aa3e3-20b4-4e6d-90b0-6606f0d14f64";
}

- (NSString *)contactChannelId
{
    return @"c8b8f36c-f1c3-47e2-8664-b96d54b2a978";
}

- (NSString *)messageId
{
    return @"e7881016-8a75-445b-9f3f-13c88badce14";
}

- (NSString *)eventId
{
    return @"1d35bd5a-e2f5-4d91-8355-80627a80ace8";
}

@end
