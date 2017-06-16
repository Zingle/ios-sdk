//
//  ZNGConversationContactToService.h
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

@interface ZNGConversationContactToService : ZNGConversation

@property (nonatomic, readonly) NSString * contactChannelValue;
@property (nonatomic, readonly) NSString * channelTypeId;
@property (nonatomic, readonly) ZNGContactService * contactService;

- (instancetype) initFromContactChannelValue:(NSString *)aContactChannelValue
                               channelTypeId:(NSString *)aChannelTypeId
                                   contactId:(NSString *)aContactId
                            toContactService:(ZNGContactService *)aContactService
                           withMessageClient:(ZNGMessageClient*)messageClient
                                 eventClient:(ZNGEventClient *)eventClient;

- (id) initWithMessageClient:(ZNGMessageClient *)messageClient eventClient:(ZNGEventClient *)eventClient NS_UNAVAILABLE;

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
