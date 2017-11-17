//
//  ZNGMessageData.h
//  Pods
//
//  Created by Jason Neel on 8/30/17.
//
//

#import <Foundation/Foundation.h>
#import <JSQMessagesViewController/JSQMessageData.h>

@protocol ZNGMessageData <JSQMessageData>

/**
 *  Indicates that this represents a typing indicator for the `senderId`/`senderDisplayName`
 */
- (BOOL) isTypingIndicator;

@end
