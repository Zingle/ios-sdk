//
//  ZNGParticipant.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGParticipant.h"

@implementation ZNGParticipant

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{ @"participantId" : @"id", @"channelValue" : @"channel_value" };
}

+ (ZNGParticipant *)participantForServiceId:(NSString *)serviceId
{
    ZNGParticipant *serviceParticipant = [[ZNGParticipant alloc] init];
    serviceParticipant.type = ZNGParticipantTypeService;
    serviceParticipant.participantId = serviceId;
    return serviceParticipant;
}

+ (ZNGParticipant *)participantForContactId:(NSString *)contactId withContactChannelValue:(NSString *)contactChannelValue
{
    ZNGParticipant *contactParticipant = [[ZNGParticipant alloc] init];
    contactParticipant.type = ZNGParticipantTypeContact;
    contactParticipant.participantId = contactId;
    contactParticipant.channelValue = contactChannelValue;
    return contactParticipant;
}

@end
