//
//  ZNGService.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGAccount.h"
#import "ZNGAccountPlan.h"
#import "ZNGServiceAddress.h"
#import "ZNGChannelType.h"

@class ZNGAutomation;
@class ZNGChannel;
@class ZNGChannelType;
@class ZNGLabel;
@class ZNGContactField;
@class ZNGSetting;
@class ZNGTemplate;

@interface ZNGService : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* serviceId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* businessName;
@property(nonatomic, strong) NSString* timeZone;
@property(nonatomic, strong) ZNGAccount* account;
@property(nonatomic, strong) ZNGAccountPlan* plan;
@property(nonatomic, strong) NSArray<ZNGChannel *> * channels;
@property(nonatomic, strong) NSArray<ZNGChannelType *> * channelTypes;
@property(nonatomic, strong) NSArray<ZNGLabel *> * contactLabels;
@property(nonatomic, strong) NSArray<ZNGContactField *> * contactCustomFields;
@property(nonatomic, strong) NSArray<ZNGSetting *> * settings;
@property(nonatomic, strong) NSArray<ZNGAutomation *> * automations;
@property(nonatomic, strong) NSArray<ZNGTemplate *> * templates;
@property(nonatomic, strong) ZNGServiceAddress* serviceAddress;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* updatedAt;


- (ZNGChannelType *)phoneNumberChannelType;
- (ZNGChannelType *)channelTypeWithDisplayName:(NSString *)channelDisplayName;
- (ZNGChannelType *)channelTypeWithTypeClass:(NSString *)typeClass;

- (ZNGChannel *)defaultPhoneNumberChannel;
- (ZNGChannel *)defaultChannelForType:(ZNGChannelType *)channelType;

/**
 *  Thanks to http://jira.zinglecorp.com:8080/browse/TECH-1970, there is logic for displaying a channel
 *   that depends on the country code for the channel vs. the service.  This is gross and I hate it.
 */
- (NSString *) displayNameForChannel:(ZNGChannel *)channel;

@end
