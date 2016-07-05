//
//  ZNGConversationContactToService.h
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

@interface ZNGConversationContactToService : ZNGConversation

- (instancetype) initFromContactChannelValue:(NSString *)aContactChannelValue
                               channelTypeId:(NSString *)aChannelTypeId
                                   contactId:(NSString *)aContactId
                            toContactService:(ZNGContactService *)aContactService
                           withMessageClient:(ZNGMessageClient*)messageClient;

/**
 *  Marks the specified message as "deleted by contact"
 *
 *  @param message The message to be marked as deleted
 */
- (void) deleteMessage:(ZNGMessage *)message;

/**
 *  Marks all messages in the conversation as "deleted by contact"
 */
- (void) deleteAllMessages;

@end
