//
//  ZNGContactService.h
//  Pods
//
//  Created by Robert Harrison on 5/23/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGMessage.h"

@interface ZNGContactService : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactId;
@property(nonatomic, strong) NSString* accountId;
@property(nonatomic, strong) NSString* serviceId;
@property(nonatomic, strong) NSNumber* unreadMessageCount;
@property(nonatomic, strong) NSString* serviceDisplayName;
@property(nonatomic, strong) NSString* accountDisplayName;
@property(nonatomic, strong) ZNGMessage* lastMessage;

@end
