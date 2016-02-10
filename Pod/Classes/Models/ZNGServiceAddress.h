//
//  ZNGServiceAddress.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGServiceAddress : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *postalCode;

@end
