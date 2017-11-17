//
//  ZNGPendingResponseOrNote.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/24/17.
//

#import <Foundation/Foundation.h>
#import "ZNGMessageData.h"

@class ZNGUser;

extern NSString * _Nonnull const ZNGPendingResponseTypeMessage;
extern NSString * _Nonnull const ZNGPendingResponseTypeInternalNote;

/**
 *  Represents (contains) a `ZNGUser` who is responding or adding a note to a conversation.
 */
@interface ZNGPendingResponseOrNote : NSObject <ZNGMessageData>

/**
 *  Event type, initially either "message" or "note"
 */
@property (nonatomic, copy, nonnull) NSString * eventType;

/**
 *  The user who is typing a response/note
 */
@property (nonatomic, strong, nonnull) ZNGUser * user;

- (id _Nonnull) initWithUser:(ZNGUser * _Nonnull)user eventType:(NSString * _Nonnull)eventType;

@end
