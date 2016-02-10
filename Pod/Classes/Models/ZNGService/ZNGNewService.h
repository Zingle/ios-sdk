//
//  ZNGNewService.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGServiceAddress.h"
#import "ZNGService.h"

@interface ZNGNewService : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *businessName;
@property (nonatomic, strong) NSString *timeZone;
@property (nonatomic, strong) NSString *planCode;
@property (nonatomic, strong) ZNGServiceAddress *serviceAddress;

- (id)initWithService:(ZNGService *)service;

@end
