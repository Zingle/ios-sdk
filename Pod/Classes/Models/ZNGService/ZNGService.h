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

@class ZNGChannel;
@class ZNGChannelType;
@class ZNGLabel;
@class ZNGContactField;
@class ZNGSetting;

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
@property(nonatomic, strong) ZNGServiceAddress* serviceAddress;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* updatedAt;

- (ZNGChannelType *)channelTypeWithDisplayName:(NSString *)channelDisplayName;

@end
