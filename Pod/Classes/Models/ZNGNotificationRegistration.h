//
//  ZNGNotificationRegistration.h
//  Pods
//
//  Created by Ryan Farley on 4/5/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNotificationRegistration : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString *deviceIdentifier;
@property (nonatomic, strong, nullable) NSArray *serviceIds;
@property (nonatomic, strong, nullable) NSString *operatingSystem;

/**
 *  Optional string specifying "dev" or "production"
 *
 *  This will determine which APNS certificate the server will attempt to use.
 */
@property (nonatomic, copy, nullable) NSString * pushEnvironment;

@end
