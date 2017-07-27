//
//  ZNGUser.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class ZNGUserAuthorization;

@interface ZNGUser : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong, nullable) NSString * userId;
@property(nonatomic, strong, nullable) NSString* username;
@property(nonatomic, strong, nullable) NSString* email;
@property(nonatomic, strong, nullable) NSString* firstName;
@property(nonatomic, strong, nullable) NSString* lastName;
@property(nonatomic, strong, nullable) NSString* title;
@property(nonatomic, strong, nullable) NSArray* serviceIds;
@property(nonatomic, strong, nullable) NSURL * avatarUri;

- (NSString * _Nullable) fullName;

+ (instancetype) userFromUserAuthorization:(ZNGUserAuthorization *)auth;
+ (instancetype) userFromSocketData:(NSDictionary *)data;

NS_ASSUME_NONNULL_END

@end
