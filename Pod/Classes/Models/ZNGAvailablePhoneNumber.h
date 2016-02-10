//
//  ZNGAvailablePhoneNumber.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGAvailablePhoneNumber : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *formattedPhoneNumber;
@property (nonatomic, strong) NSString *country;

@end
