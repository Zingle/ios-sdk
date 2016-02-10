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

@interface ZNGService : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *businessName;
@property (nonatomic, strong) NSString *timeZone;
@property (nonatomic, strong) ZNGAccount *account;
@property (nonatomic, strong) ZNGAccountPlan *plan;
@property (nonatomic ,strong) NSArray *channels;
@property (nonatomic, strong) NSArray *channelTypes;
@property (nonatomic, strong) NSArray *contactLabels;
@property (nonatomic, strong) NSArray *contactCustomFields;
@property (nonatomic, strong) NSArray *settings;
@property (nonatomic, strong) ZNGServiceAddress *serviceAddress;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;

@end
