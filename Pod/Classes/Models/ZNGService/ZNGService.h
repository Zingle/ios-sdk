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
@class ZNGPrinter;
@class ZNGSetting;
@class ZNGTemplate;


@interface ZNGService : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong, nonnull) NSString* serviceId;
@property(nonatomic, strong, nullable) NSString* displayName;
@property(nonatomic, strong, nullable) NSString* businessName;
@property(nonatomic, strong, nullable) NSString* timeZone;
@property(nonatomic, strong, nullable) ZNGAccount* account;
@property(nonatomic, strong, nullable) ZNGAccountPlan* plan;
@property(nonatomic, strong, nullable) NSArray<ZNGChannel *> * channels;
@property(nonatomic, strong, nullable) NSArray<ZNGChannelType *> * channelTypes;
@property(nonatomic, strong, nullable) NSArray<ZNGLabel *> * contactLabels;
@property(nonatomic, strong, nullable) NSArray<ZNGContactField *> * contactCustomFields;
@property(nonatomic, strong, nullable) NSArray<ZNGSetting *> * settings;
@property(nonatomic, strong, nullable) NSArray<ZNGAutomation *> * automations;
@property(nonatomic, strong, nullable) NSArray<ZNGTemplate *> * templates;
@property(nonatomic, strong, nullable) NSArray<ZNGPrinter *> * printers;
@property(nonatomic, strong, nullable) ZNGServiceAddress* serviceAddress;
@property(nonatomic, strong, nullable) NSDate* createdAt;
@property(nonatomic, strong, nullable) NSDate* updatedAt;

- (NSArray<ZNGAutomation *> * _Nullable) activeAutomations;

- (BOOL) isTextRelay;

- (ZNGChannelType * _Nullable)phoneNumberChannelType;
- (ZNGChannelType * _Nullable)channelTypeWithDisplayName:(NSString * _Nonnull)channelDisplayName;
- (ZNGChannelType * _Nullable)channelTypeWithTypeClass:(NSString * _Nonnull)typeClass;

- (ZNGChannel * _Nullable)defaultPhoneNumberChannel;
- (ZNGChannel * _Nullable)defaultChannelForType:(ZNGChannelType * _Nonnull)channelType;

// HotSOS settings
- (NSString * _Nullable)hotsosUserName;
- (NSString * _Nullable)hotsosHostName;
- (NSString * _Nullable)hotsosPassword;


/**
 *  Thanks to http://jira.zinglecorp.com:8080/browse/TECH-1970, there is logic for displaying a channel
 *   that depends on the country code for the channel vs. the service.  This is gross and I hate it.
 */
- (BOOL) shouldDisplayRawValueForChannel:(ZNGChannel * _Nonnull)channel;

@end
