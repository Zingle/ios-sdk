//
//  ZNGUserClient.h
//  Pods
//
//  Created by Jason Neel on 4/5/17.
//
//

#import <ZingleSDK/ZingleSDK.h>

@class ZNGUser;

@interface ZNGUserClient : ZNGBaseClientService

- (void) userWithId:(NSString *)userId
            success:(void (^)(ZNGUser* user, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

@end
