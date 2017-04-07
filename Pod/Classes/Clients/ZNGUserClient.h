//
//  ZNGUserClient.h
//  Pods
//
//  Created by Jason Neel on 4/5/17.
//
//

#import <ZingleSDK/ZNGBaseClientAccount.h>

@class ZNGUser;

@interface ZNGUserClient : ZNGBaseClientAccount

- (void) userWithId:(NSString *)userId
            success:(void (^)(ZNGUser* user, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

@end
