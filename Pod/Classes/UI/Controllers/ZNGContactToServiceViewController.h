//
//  ZNGContactToServiceViewController.h
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import <ZingleSDK/ZingleSDK.h>
#import <ZingleSDK/ZNGConversationViewController.h>
#import "ZNGConversationContactToService.h"

@interface ZNGContactToServiceViewController : ZNGConversationViewController

@property (nonatomic, strong, nullable) ZNGConversationContactToService * conversation;

#pragma mark - Configuration

/**
 *  Whether messages can be marked as deleted by contact and hidden.  Defaults to YES.
 */
@property (nonatomic, assign) BOOL allowDeletion;

/**
 *  If set, employee names will appear over each incoming message.  Defaults to YES.
 */
@property (nonatomic, assign) BOOL showEmployeeNamesOverMessages;

@end
