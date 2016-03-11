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
    [sdk setToken:token andKey:key];
}

- (NSString *)accountId
{
    return @"bbc1f555-bc73-447b-90e5-4893e895acb7";
}

- (NSString *)planId
{
    return @"14c602b5-202b-47b4-9753-895785c868df";
}

- (NSString *)serviceId
{
    return @"e545a46e-bfcd-4db2-bfee-8e590fdcb33f";
}

- (NSString *)timeZone
{
    return @"America/Los_Angeles";
}

- (NSString *)planCode
{
    return @"enterprise_platinum";
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
    plan.planId = @"14c602b5-202b-47b4-9753-895785c868df";
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
    account.accountId = @"bbc1f555-bc73-447b-90e5-4893e895acb7";
    
    return account;
}

- (NSString *)serviceChannelId
{
    return @"5dae0d6f-31ac-4f92-b393-e1648b129b97";
}

- (ZNGChannelType *)channelType
{
    ZNGChannelType *channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"0a293ea3-4721-433e-a031-610ebcf43255";
    
    return channelType;
}

- (ZNGServiceChannel *)serviceChannelWithValue:(NSString *)value
{
    ZNGServiceChannel *serviceChannel = [[ZNGServiceChannel alloc] init];
    serviceChannel.displayName = @"Test service channel";
    serviceChannel.value = value;
    serviceChannel.channelType = [self channelType];
    serviceChannel.country = @"US";
    serviceChannel.isDefaultForType = false;
    
    return serviceChannel;
}

- (ZNGNewContactChannel *)contactChannelWithValue:(NSString *)value
{
    ZNGContactChannel *contactChannel = [[ZNGContactChannel alloc] init];
    contactChannel.displayName = @"MOBILE";
    contactChannel.value = value;
    contactChannel.channelType = [self channelType];
    contactChannel.country = @"US";
    contactChannel.isDefaultForType = false;
    
    ZNGNewContactChannel *newChannel = [[ZNGNewContactChannel alloc] initWithContactChannel:contactChannel];
    
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
    return @"4e4ea449-762e-4b18-a53d-8eb98f6dfc99";
}

@end
