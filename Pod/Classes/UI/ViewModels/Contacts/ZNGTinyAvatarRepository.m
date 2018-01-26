//
//  ZNGTinyAvatarRepository.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/25/18.
//

#import "ZNGTinyAvatarRepository.h"
#import "UIImage+CircleCrop.h"
#import "ZNGUser.h"

@import SDWebImage;

@implementation ZNGTinyAvatarRepository
{
    CGFloat diameter;
    
    NSCache * avatarCache;
}

- (id) initWithAvatarDiameter:(CGFloat)theDiameter
{
    self = [super init];
    
    if (self != nil) {
        diameter = theDiameter;
        
        avatarCache = [[NSCache alloc] init];
        avatarCache.countLimit = 10;
    }
    
    return self;
}

- (UIImage * _Nullable) tinyAvatarForUser:(ZNGUser * _Nonnull)user
{
    if (user.userId == nil) {
        return nil;
    }
    
    return [avatarCache objectForKey:user.userId];
}

- (void) fetchTinyAvatarForUser:(ZNGUser * _Nonnull)user completion:(void (^ _Nullable)(UIImage * _Nullable avatar))completion
{
    UIImage * existingAvatar = [self tinyAvatarForUser:user];
    
    if (existingAvatar != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(existingAvatar);
        });
        
        return;
    }

    if (user.avatarUri == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
        return;
    }
    
    // Load/retrieve the user's avatar from cache, resize it on a background thread, and call the completion block.
    [[SDWebImageManager sharedManager] loadImageWithURL:user.avatarUri options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        // Did we fail?
        if (image == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
            return;
        }
        
        // Resize the image in a low priority background queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            UIImage * tinyImage = [image imageCroppedToCircleOfDiameter:diameter withScale:0.0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (user.userId != nil) {
                    [avatarCache setObject:tinyImage forKey:user.userId];
                }
                
                completion(tinyImage);
            });
        });
    }];
}

@end
