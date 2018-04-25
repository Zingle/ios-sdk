//
//  ZNGUser.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class ZNGService;
@class ZNGUserAuthorization;
@class ZNGUserSettings;

@interface ZNGUser : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong, nullable) NSString * userId;
@property(nonatomic, assign) int numericId;
@property(nonatomic, strong, nullable) NSString* username;
@property(nonatomic, strong, nullable) NSString* email;
@property(nonatomic, strong, nullable) NSString* firstName;
@property(nonatomic, strong, nullable) NSString* lastName;
@property(nonatomic, strong, nullable) NSString* title;
@property(nonatomic, strong, nullable) NSArray* serviceIds;
@property(nonatomic, strong, nullable) NSURL * avatarUri;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, NSArray<NSString *> *> * servicePrivileges;
@property(nonatomic, strong, nullable) ZNGUserSettings * settings;
@property (nonatomic, assign) BOOL isOnline;

- (NSString * _Nullable) fullName;

- (BOOL) canMonitorAllTeamsOnService:(ZNGService *)service;

- (NSArray<NSString *> * _Nullable) privilegesForService:(ZNGService *)service;

+ (instancetype) userFromSocketData:(NSDictionary *)data;

NS_ASSUME_NONNULL_END

@end
