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

+ (ZNGParticipant *)participantForService:(ZNGService *)service
{
    ZNGParticipant *serviceParticipant = [[ZNGParticipant alloc] init];
    serviceParticipant.type = ZNGParticipantTypeService;
    serviceParticipant.participantId = service.serviceId;
    serviceParticipant.name = service.displayName;
    return serviceParticipant;
}

+ (ZNGParticipant *)participantForContact:(ZNGContact *)contact withContactChannelValue:(NSString *)contactChannelValue
{
    ZNGParticipant *contactParticipant = [[ZNGParticipant alloc] init];
    contactParticipant.type = ZNGParticipantTypeContact;
    contactParticipant.participantId = contact.contactId;
    contactParticipant.channelValue = contactChannelValue;
    return contactParticipant;
}

@end
