//
//  ZNGServiceToContactViewController.h
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import <ZingleSDK/ZNGConversationViewController.h>
#import "ZNGConversationServiceToContact.h"

@interface ZNGServiceToContactViewController : ZNGConversationViewController

@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@end
