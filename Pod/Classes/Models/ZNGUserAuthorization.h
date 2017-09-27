//
//  ZNGUserAuthorization.h
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGUserAuthorization : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * authorizationClass;
@property (nonatomic, strong, nullable) NSString * userId;
@property (nonatomic, strong, nullable) NSString * username;
@property (nonatomic, strong, nullable) NSString * email;
@property (nonatomic, strong, nullable) NSString * firstName;
@property (nonatomic, strong, nullable) NSString * lastName;
@property (nonatomic, strong, nullable) NSString * title;
@property (nonatomic, strong, nullable) NSArray<NSString *> * accountIds;
@property (nonatomic, strong, nullable) NSArray<NSString *> * serviceIds;
@property (nonatomic, strong, nullable) NSURL * avatarUri;

- (NSString * _Nullable) displayName;

@end
