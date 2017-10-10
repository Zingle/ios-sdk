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
#import "ZingleAccountSession.h"

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
                           success:(void (^)(void))success
                           failure:(void (^)(ZNGError * error))failure
{
    NSString * path = [NSString stringWithFormat:@"accounts/%@/users/%@/avatar", self.accountId, userId];
    
    [self deleteWithPath:path success:^(ZNGStatus * _Nonnull status) {
        [self refreshUserData];
        
        if (success != nil) {
            success();
        }
    } failure:failure];
}

- (void) uploadAvatar:(UIImage *)avatarImage
        forUserWithId:(NSString *)userId
              success:(void (^)(void))success
              failure:(void (^)(ZNGError * error))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * imageData = UIImageJPEGRepresentation([self imageDownsizedToReasonableAvatarSize:avatarImage], 0.5);
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
                                      @"content_type": contentType,
                                      @"base64": [imageData base64EncodedStringWithOptions:0]
                                      };
        
        [self putWithPath:path parameters:parameters responseClass:nil success:^(id  _Nonnull responseObject, ZNGStatus * _Nonnull status) {
            [self refreshUserData];
            
            if (success != nil) {
                success();
            }
        } failure:failure];
    });
}

- (UIImage *) imageDownsizedToReasonableAvatarSize:(UIImage *)originalImage
{
    if (originalImage == nil) {
        return nil;
    }
    
    static const CGFloat maxDimension = 800.0;
    CGFloat widthDownscale = maxDimension / originalImage.size.width;
    CGFloat heightDownscale = maxDimension / originalImage.size.height;
    CGFloat downscale = MIN(widthDownscale, heightDownscale);
    
    if (downscale >= 1.0) {
        return originalImage;
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, originalImage.size.width * downscale, originalImage.size.height * downscale);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, originalImage.scale);
    
    [originalImage drawInRect:rect];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void) refreshUserData
{
    if ([self.session isKindOfClass:[ZingleAccountSession class]]) {
        [(ZingleAccountSession *)self.session updateUserData];
    }
}

@end
