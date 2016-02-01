//
//  ZNGQuickStart.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/1/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZNGQuickStart.h"

@interface ZNGQuickStart ()

@property (nonatomic) BOOL authenticated;
@property (nonatomic, retain) ZNGAccount *firstAccount;
@property (nonatomic, retain) ZNGService *myNewService;
@property (nonatomic, retain) ZNGContact *myNewContact;
@property (nonatomic, retain) NSArray *contactCustomFields;
@end

@implementation ZNGQuickStart

- (void)startAsynchronousTest
{
    [[ZingleSDK sharedSDK] setToken:@"TOKEN" andKey:@"KEY"];
    
    // Uncomment the following line to see detailed logging on the underlying API
    [[ZingleSDK sharedSDK] setGlobalLogLevel:ZINGLE_LOG_LEVEL_VERBOSE];
    
    // Ensure your API credential are valid
    [[ZingleSDK sharedSDK] validateCredentialsWithCompletionBlock:^{
        self.authenticated = YES;
        [self getAllMyAccounts];
    } errorBlock:^(NSError *error) {
        self.authenticated = NO;
        NSLog(@"Authentication Failed: %@", error);
    }];
}


- (void)getAllMyAccounts
{
    // Searches for all Accounts your credentials grant access to
    [[ZingleSDK sharedSDK] allAccountsWithCompletionBlock:^(NSArray *accounts) {
        
        if( [accounts count] == 0 ) {
            NSLog(@"You don't have access to any accounts.");
            return;
        }
        
        // Grab the first account returned - change this if you want to use a different account
        self.firstAccount = [accounts firstObject];
        
        [self findSandboxPlan];
    } errorBlock:^(NSError *error) {
        NSLog( @"Getting Accounts Failed: %@", error );
    }];
}

- (void)findSandboxPlan
{
    // Search for the "sandbox" plan, which grants special privileges for development testing.
    [self.firstAccount findPlanByCode:@"sandbox" withCompletionBlock:^(ZNGPlan *plan){
        [self createServiceWithPlan:plan];
    } errorBlock:^(NSError *error) {
        NSLog( @"Finding Sandbox Plan Failed: %@", error );
    }];
}

- (void)createServiceWithPlan:(ZNGPlan *)sandboxPlan
{
    // Create a new Service using the sandbox plan
    self.myNewService                    = [self.firstAccount newService];
    self.myNewService.plan               = sandboxPlan;
    self.myNewService.timeZone           = @"America/New_York";
    self.myNewService.displayName        = @"Super AWesome SVCS2345";
    self.myNewService.address.address    = @"1234 Jovin Street";
    self.myNewService.address.city       = @"Carlsbad";
    self.myNewService.address.state      = @"CA";
    self.myNewService.address.postalCode = @"92101";
    self.myNewService.address.country    = @"US";
    
    // Once the Service is saved, you should be able to login
    // to https://dashboard.zingle.me and see your new Service
    [self.myNewService saveWithCompletionBlock:^{
        [self findPhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"Creating New Service Failed: %@", error );
    }];
}

- (void)findPhoneNumber
{
    // Search for available SMS-capable phone numbers
    ZNGAvailablePhoneNumberSearch *phoneNumberSearch = [[ZNGAvailablePhoneNumberSearch alloc] init];
    phoneNumberSearch.country = @"US";
    phoneNumberSearch.areaCode = @"858";
    
    [phoneNumberSearch searchWithCompletionBlock:^(NSArray *availablePhoneNumbers) {
        if( [availablePhoneNumbers count] == 0 ) {
            NSLog(@"No available phone numbers found with Country=%@ and areaCode=%@.",
                  phoneNumberSearch.country, phoneNumberSearch.areaCode);
            return;
        }
        
        // Grab the first available phone number in the array, and build a new Service Channel
        ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
        
        [self provisionPhoneNumber:firstAvailablePhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"Finding Phone Numbers Failed: %@", error );
    }];
}

- (void)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber
{
    [self.myNewService provisionPhoneNumber:availablePhoneNumber asDefaultChannel:YES withCompletionBlock:^(ZNGServiceChannel *newServiceChannel) {
        
        [self populateContactCustomFieldsOnService];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error Provisioning Phone Number: %@", error);
    }];
}

- (void)populateContactCustomFieldsOnService
{
    [self.myNewService populateAllContactCustomFieldsWithCompletionBlock:^{
        
        [self saveNewContact];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error populating custom fields on Service: %@", error);
    }];
}

- (void)saveNewContact
{
    self.myNewContact = [self.myNewService newContact];
    
    [self.myNewContact setCustomFieldValueTo:@"David" forCustomFieldWithName:@"First Name"];
    [self.myNewContact setCustomFieldValueTo:@"Peace" forCustomFieldWithName:@"Last Name"];
    
    [self.myNewContact saveWithCompletionBlock:^{
        
        NSLog(@"New Contact: %@", self.myNewContact);
        [self sendMessage];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error saving new contact: %@", error);
    }];
}

- (void)sendMessage
{
    
}

@end
