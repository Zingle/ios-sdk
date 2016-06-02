//
//  ZNGParticipant.h
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGService.h"
#import "ZNGContact.h"

@interface ZNGParticipant : MTLModel<MTLJSONSerializing>

typedef NS_ENUM(NSInteger, ZNGParticipantType) {
    ZNGParticipantTypeContact,
    ZNGParticipantTypeService
};

@property(nonatomic) ZNGParticipantType type;
@property(nonatomic, strong) NSString* participantId;
@property(nonatomic, strong) NSString* channelType;
@property(nonatomic, strong) NSString* channelValue;
@property(nonatomic, strong) NSString* name;

+ (ZNGParticipant *)participantForServiceId:(NSString *)serviceId withServiceChannelValue:(NSString *)serviceChannelValue;
+ (ZNGParticipant *)participantForContactId:(NSString *)contactId withContactChannelValue:(NSString *)contactChannelValue;

@end
