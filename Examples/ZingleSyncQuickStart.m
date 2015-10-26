//
//  ZingleSyncQuickStart.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZingleSyncQuickStart.h"
#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZNGServiceSearch.h"
#import "ZNGTimeZoneSearch.h"
#import "ZNGPlanSearch.h"
#import "ZNGService.h"
#import "ZingleModel.h"
#import "ZNGContactCustomFieldSearch.h"
#import "ZNGLabelSearch.h"
#import "ZNGContactSearch.h"
#import "ZNGCustomField.h"
#import "ZNGAddress.h"
#import "ZNGServiceChannel.h"
#import "ZNGAvailablePhoneNumberSearch.h"
#import "ZNGAvailablePhoneNumber.h"
#import "ZNGPlan.h"
#import "ZNGAccountSearch.h"
#import "ZNGAccount.h"
#import "ZNGContactSearch.h"
#import "ZNGLabel.h"
#import "ZNGContact.h"
#import "ZNGMessage.h"

@interface ZingleSyncQuickStart ()

@end


@implementation ZingleSyncQuickStart

- (void)startSynchronousTest
{
    [[ZingleSDK sharedSDK] setToken:@"TOKEN" andKey:@"KEY"];
    
    // Uncomment the following line to see detailed logging on the underlying API
     [[ZingleSDK sharedSDK] setGlobalLogLevel:ZINGLE_LOG_LEVEL_VERBOSE];
    
    [[ZingleSDK sharedSDK] validateCredentialsWithError:nil];
    NSArray *accounts =  [[ZingleSDK sharedSDK] allAccountsWithError:nil];
    
    if( [accounts count] == 0 ) {
        NSLog(@"You don't have access to any accounts.");
        return;
    }
    
    ZNGAccount *firstAccount = [accounts firstObject];
    ZNGPlan *sandboxPlan = [firstAccount findPlanByCode:@"sandbox" withError:nil];
    
    ZNGService *myNewService        = [firstAccount newService];
    myNewService.plan               = sandboxPlan;
    myNewService.timeZone           = @"America/New_York";
    myNewService.displayName        = @"Super AWesome SVCS2345";
    myNewService.address.address    = @"1234 Jovin Street";
    myNewService.address.city       = @"Carlsbad";
    myNewService.address.state      = @"CA";
    myNewService.address.postalCode = @"92101";
    myNewService.address.country    = @"US";
    [myNewService saveWithError:nil];
    
    ZNGAvailablePhoneNumberSearch *phoneNumberSearch = [[ZNGAvailablePhoneNumberSearch alloc] init];
    phoneNumberSearch.country = @"US";
    phoneNumberSearch.areaCode = @"858";
    
    NSArray *availablePhoneNumbers = [phoneNumberSearch searchWithError:nil];
    
    if( [availablePhoneNumbers count] == 0 ) {
        NSLog(@"No available phone numbers found with Country=%@ and areaCode=%@.",
              phoneNumberSearch.country, phoneNumberSearch.areaCode);
        return;
    }
    
    ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
    [myNewService provisionPhoneNumber:availablePhoneNumber asDefaultChannel:YES withError:nil];
    
    ZNGContact *myNewContact = [myNewService newContact];
    
    [myNewContact setCustomFieldValueTo:@"David" forCustomFieldWithName:@"First Name"];
    [myNewContact setCustomFieldValueTo:@"Peace" forCustomFieldWithName:@"Last Name"];
    
    [myNewContact saveWithError:nil];
}

@end
