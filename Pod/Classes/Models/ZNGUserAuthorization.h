//
//  ZNGUserAuthorization.h
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGUserAuthorization : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString* authorizationClass;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * title;

@end
