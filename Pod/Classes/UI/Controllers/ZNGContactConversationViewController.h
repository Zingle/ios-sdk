//
//  ZNGContactConversationViewController.h
//  Pods
//
//  Created by Jason Neel on 6/16/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

/**
 *  This subclass handles the case of a contact conversation controller, a controller that has fewer properties and less power.
 *  
 *  It follows naturally that this class hierarchy is reversed.  This is due to necessity and the normal ZNGConversaitonViewController existing first.
 *
 *  This entire conversation controller is a prime candidate for refactoring since it is mostly made from a ripped off and renamed copy of
 *   JSQMessagesViewController from https://github.com/jessesquires/JSQMessagesViewController/
 */
@interface ZNGContactConversationViewController : ZNGConversationViewController



@end
