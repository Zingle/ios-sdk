//
//  ZNGNotificationRegistration.h
//  Pods
//
//  Created by Ryan Farley on 4/5/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNotificationRegistration : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *deviceIdentifier;
@property (nonatomic, strong) NSArray *serviceIds;
@property (nonatomic, strong) NSString *operatingSystem;

@end
