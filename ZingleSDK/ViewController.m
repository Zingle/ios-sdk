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
#import "ZNGMessageSearch.h"
#import "ZNGMessageAttachment.h"

@interface ViewController ()

@property (nonatomic, retain) ZNGConversationViewController *conversationVC;
@property (nonatomic, retain) ZingleAsyncQuickStart *async;
@property (nonatomic, retain) ZNGContact *contact;
@property (nonatomic, retain) ZNGService *service;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (IBAction)launchConversationClicked:(id)sender
{
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
