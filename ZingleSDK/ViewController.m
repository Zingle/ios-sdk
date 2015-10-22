//
//  ViewController.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ViewController.h"
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
#import "ZingleAsyncQuickStart.h"
#import "ZingleSyncQuickStart.h"
#import "ZNGConversationViewController.h"
#import "ZNGArrowView.h"
#import "ZNGContact.h"
#import "ZNGContactChannel.h"
#import "ZNGConversation.h"
#import "ZNGMessageCorrespondent.h"

@interface ViewController ()

@property (nonatomic, retain) ZNGConversationViewController *conversationVC;
@property (nonatomic, retain) ZingleAsyncQuickStart *async;
@property (nonatomic, retain) ZNGContact *contact;
@property (nonatomic, retain) ZNGService *service;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    
    [[ZingleSDK sharedSDK] setToken:@"TOKEN" andKey:@"KEY"];
    
    // Uncomment the following line to see detailed logging on the underlying API
    [[ZingleSDK sharedSDK] setGlobalLogLevel:ZINGLE_LOG_LEVEL_VERBOSE];
    
    [[ZingleSDK sharedSDK] allAccountsWithCompletionBlock:^(NSArray *accounts) {
        ZNGAccount *account = [accounts firstObject];
        
        NSArray *services = [account allServicesWithError:nil];
        self.service = [services firstObject];

        self.contact = [self.service newContact];
        
        [self.contact setCustomFieldValueTo:@"David" forCustomFieldWithName:@"First Name"];
        [self.contact setCustomFieldValueTo:@"Peace" forCustomFieldWithName:@"Last Name"];
        
        [self.contact saveWithError:nil];
        
        ZNGContactChannel *channel = [self.contact newChannel];
        channel.channelType = [self.service firstChannelTypeWithClass:@"UserDefinedChannel" andDisplayName:@"Reservation Number"];
        channel.value = @"123489-2144";
        [channel saveWithError:nil];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error fetching accounts: %@", error);
    }];
    
    
    [super viewDidLoad];
}

- (IBAction)launchConversationClicked:(id)sender
{
    ZNGChannelType *channelType = [self.service firstChannelTypeWithClass:@"UserDefinedChannel" andDisplayName:@"Reservation Number"];
    
    ZNGMessageCorrespondent *from = [[ZNGMessageCorrespondent alloc] init];
    [from setCorrespondentType:ZINGLE_CORRESPONDENT_TYPE_CONTACT];
    [from setChannelValue:@"123489-2144"];
    
    ZNGMessageCorrespondent *to = [[ZNGMessageCorrespondent alloc] init];
    [to setCorrespondent:self.service];
    
    ZNGConversation *conversation = [[ZingleSDK sharedSDK] conversationFrom:from to:to usingChannelType:channelType];
    
    self.conversationVC = [[ZNGConversationViewController alloc] initWithConversation:conversation];
    
    [self presentViewController:self.conversationVC animated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
