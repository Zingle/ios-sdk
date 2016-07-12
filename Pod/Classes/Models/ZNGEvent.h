//
//  ZNGEvent.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGUser.h"
#import "ZNGAutomation.h"
#import "ZNGMessage.h"

@interface ZNGEvent : MTLModel<MTLJSONSerializing, JSQMessageData>

@property(nonatomic, strong) NSString* eventId;
@property(nonatomic, strong) NSString* contactId;
@property(nonatomic, strong) NSString* eventType;
@property(nonatomic, strong) NSString* body;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) ZNGUser* triggeredByUser;
@property(nonatomic, strong) ZNGAutomation* automation;
@property(nonatomic, strong) ZNGMessage* message;

+ (instancetype) eventForNewMessage:(ZNGMessage *)message;

- (BOOL) isMessage;
- (BOOL) isNote;

@end
