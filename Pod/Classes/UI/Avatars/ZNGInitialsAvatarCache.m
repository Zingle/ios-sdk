//
//  ZNGInitialsAvatarCache.m
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import "ZNGInitialsAvatarCache.h"
#import "ZNGInitialsAvatar.h"
#import "ZNGImageAvatar.h"
#import "ZNGParticipant.h"
#import "NSString+Initials.h"

@implementation ZNGInitialsAvatarCache
{
    NSCache * incomingCache;
    NSCache * outgoingCache;
    
    // Avatar images, indexed by URI string
    NSCache * avatarImageCache;
    
    // Avatar URIs, index by contact ID
    NSCache * avatarURIs;
}

+ (instancetype) sharedCache
{
    static ZNGInitialsAvatarCache * singleton;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        incomingCache = [[NSCache alloc] init];
        incomingCache.countLimit = 20;
        outgoingCache = [[NSCache alloc] init];
        outgoingCache.countLimit = 20;
        
        avatarImageCache = [[NSCache alloc] init];
        avatarImageCache.countLimit = 15;
        avatarURIs = [[NSCache alloc] init];
        avatarURIs.countLimit = 100;
        
        _avatarSize = CGSizeMake(32.0, 32.0);
        
        _font = [UIFont systemFontOfSize:13.0];
    }
    
    return self;
}

- (id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid fallbackImage:(UIImage *)image useCircleBackground:(BOOL)circleBackground outgoing:(BOOL)isOutgoing;
{
    NSCache * cache = (isOutgoing) ? outgoingCache : incomingCache;
    id <JSQMessageAvatarImageDataSource> avatar = [cache objectForKey:uuid];
    
    if (avatar == nil) {
        UIColor * backgroundColor = nil;
        
        if (circleBackground) {
            backgroundColor = (isOutgoing) ? self.outgoingBackgroundColor : self.incomingBackgroundColor;
        }
        
        avatar = [[ZNGImageAvatar alloc] initWithImage:image backgroundColor:backgroundColor size:self.avatarSize];
    }
    
    return avatar;
}

- (id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid nameForFallbackAvatar:(NSString *)name outgoing:(BOOL)isOutgoing;
{
    NSCache * cache = (isOutgoing) ? outgoingCache : incomingCache;
    id key = uuid ?: [NSNull null];
    id <JSQMessageAvatarImageDataSource> avatar = [cache objectForKey:key];
    
    if (avatar == nil) {
        NSString * initials = [name initials];
        UIColor * backgroundColor = (isOutgoing) ? self.outgoingBackgroundColor : self.incomingBackgroundColor;
        UIColor * textColor = (isOutgoing) ? self.outgoingTextColor : self.incomingTextColor;
        
        if (backgroundColor == nil) {
            backgroundColor = [UIColor grayColor];
        }
        if (textColor == nil) {
            textColor = [UIColor whiteColor];
        }
        
        avatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials textColor:textColor backgroundColor:backgroundColor size:self.avatarSize font:self.font];
        [cache setObject:avatar forKey:key];
    }
    
    return avatar;
}

- (void) clearCache
{
    [incomingCache removeAllObjects];
    [outgoingCache removeAllObjects];
}

@end
