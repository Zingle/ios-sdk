//
//  ZNGServiceToContactViewController.h
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import <ZingleSDK/ZNGConversationViewController.h>
#import "ZNGConversationServiceToContact.h"

@protocol  ZNGServiceToContactViewDelegate <NSObject>

@optional

/**
 *  Optional delegate method that is called when the user pressed 'Edit Contact.'
 *  If this method is implemented and returns NO, the edit contact screen will not be shown, instead allowing the delegate
 *   to present UI.
 */
- (BOOL) shouldShowEditContactScreenForContact:(nonnull ZNGContact *)contact;

@end


@interface ZNGServiceToContactViewController : ZNGConversationViewController

@property (nonatomic, strong, nullable) ZNGConversationServiceToContact * conversation;

@property (nonatomic, weak, nullable) id <ZNGServiceToContactViewDelegate> delegate;

@end
