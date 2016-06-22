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
                                 toServiceId:(NSString *)aServiceId
                           withMessageClient:(ZNGMessageClient*)messageClient;

@end
