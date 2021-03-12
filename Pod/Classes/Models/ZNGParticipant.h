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

NS_ASSUME_NONNULL_BEGIN

@interface ZNGParticipant : MTLModel<MTLJSONSerializing>

typedef NS_ENUM(NSInteger, ZNGParticipantType) {
    ZNGParticipantTypeContact,
    ZNGParticipantTypeService
};

@property(nonatomic) ZNGParticipantType type;
@property(nonatomic, strong, nonnull) NSString* participantId;
@property(nonatomic, strong, nullable) NSString* channelType;
@property(nonatomic, strong, nullable) NSString* channelValue;
@property(nonatomic, strong, nullable) NSString* channelId;
@property(nonatomic, strong, nullable) NSString* name;

+ (ZNGParticipant *)participantForServiceId:(NSString *)serviceId withServiceChannelValue:(NSString *)serviceChannelValue;
+ (ZNGParticipant *)participantForContactId:(NSString *)contactId withContactChannelValue:(NSString *)contactChannelValue;

NS_ASSUME_NONNULL_END

@end
