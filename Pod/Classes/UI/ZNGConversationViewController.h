//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContact.h"
#import "ZNGError.h"
#import "ZNGConversation.h"

@interface ZNGConversationViewController : UIViewController<ZNGConversationDelegate>

- (id)initWithConversation:(ZNGConversation *)conversation;

@end
