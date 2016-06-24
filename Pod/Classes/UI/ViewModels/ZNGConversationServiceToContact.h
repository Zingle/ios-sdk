//
//  ZNGConversationServiceToContact.h
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

@interface ZNGConversationServiceToContact : ZNGConversation

@property (nonatomic, readonly) ZNGContact * contact;

- (id) initFromServiceToContact:(ZNGContact *)aContact withMessageClient:(ZNGMessageClient *)messageClient;
- (id) initFromServiceToContact:(ZNGContact *)aContact usingChannel:(ZNGChannel *)aChannel withMessageClient:(ZNGMessageClient *)messageClient NS_DESIGNATED_INITIALIZER;

@end
