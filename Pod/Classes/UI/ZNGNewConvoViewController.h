//
//  ZNGNewConvoViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGConversation.h"

@interface ZNGNewConvoViewController : UIViewController <ZNGConversationDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) ZNGConversation *conversation;

- (id)initWithConversation:(ZNGConversation *)conversation;

@end
