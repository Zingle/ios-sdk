//
//  ZNGUserClient.m
//  Pods
//
//  Created by Jason Neel on 4/5/17.
//
//

#import "ZNGUserClient.h"
#import "NSData+ImageType.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGUserClient

- (void) userWithId:(NSString *)userId
            success:(void (^)(ZNGUser* user, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    NSString * path = [NSString stringWithFormat:@"accounts/%@/users/%@", self.accountId, userId];

    [self getWithResourcePath:path
                responseClass:[ZNGUser class]
                      success:success
                      failure:failure];
}

- (void) deleteAvatarForUserWithId:(NSString *)userId
                           success:(void (^)())success
                           failure:(void (^)(ZNGError * error))failure
{
    NSString * path = [NSString stringWithFormat:@"accounts/%@/users/%@/avatar", self.accountId, userId];
    
    [self deleteWithPath:path success:^(ZNGStatus * _Nonnull status) {
        if (success != nil) {
            success();
        }
    } failure:failure];
}

- (void) uploadAvatar:(UIImage *)avatarImage
        forUserWithId:(NSString *)userId
              success:(void (^)())success
              failure:(void (^)(ZNGError * error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * imageData = UIImageJPEGRepresentation(avatarImage, 0.5);
        NSString * contentType = [imageData imageContentType];
        
        if (([imageData length] == 0) || ([contentType length] == 0)) {
            NSString * errorString = [NSString stringWithFormat:@"Unable to parse image data and content type from %@ image and %llu bytes",
                                      NSStringFromCGSize(avatarImage.size), (unsigned long long)[imageData length]];
            ZNGLogError(@"%@", errorString);
            
            if (failure != nil) {
                ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: errorString }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
            
            return;
        }

        
        NSString * path = [NSString stringWithFormat:@"accounts/%@/users/%@/avatar", self.accountId, userId];
        NSDictionary * parameters = @{
                                      @"content-type": contentType,
                                      @"base64": [imageData base64EncodedStringWithOptions:0]
                                      };
        
        [self putWithPath:path parameters:parameters responseClass:nil success:^(id  _Nonnull responseObject, ZNGStatus * _Nonnull status) {
            if (success != nil) {
                success();
            }
        } failure:failure];
    });
}

@end
