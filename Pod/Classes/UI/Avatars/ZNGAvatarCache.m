//
//  ZNGAvatarCache.m
//  Pods
//
//  Created by Jason Neel on 12/21/16.
//
//

#import "ZNGAvatarCache.h"
#import "ZNGInitialsAvatar.h"
#import "ZNGParticipant.h"

@implementation ZNGAvatarCache
{
    NSCache * incomingCache;
    NSCache * outgoingCache;
}

+ (instancetype) sharedCache
{
    static ZNGAvatarCache * singleton;
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
        _avatarSize = CGSizeMake(32.0, 32.0);
    }
    
    return self;
}


- (NSString *)initialsForName:(NSString *)theName
{
    NSArray<NSString *> * names = [theName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableString * initials = [[NSMutableString alloc] initWithCapacity:3];
    
    for (NSString * name in names) {
        if ([name length] > 0) {
            [initials appendFormat:@"%c", [[name uppercaseString] characterAtIndex:0]];
        }
    }
    
    if ([initials length] == 0) {
        return @"";
    }
    
    return initials;
}

- (nullable id <JSQMessageAvatarImageDataSource>) avatarForUserUUID:(NSString *)uuid name:(NSString *)name outgoing:(BOOL)isOutgoing;
{
    NSCache * cache = (isOutgoing) ? outgoingCache : incomingCache;
    id <JSQMessageAvatarImageDataSource> avatar = [cache objectForKey:uuid];
    
    if (avatar == nil) {
        NSString * initials = [self initialsForName:name];
        UIColor * backgroundColor = (isOutgoing) ? self.outgoingBackgroundColor : self.incomingBackgroundColor;
        UIColor * textColor = (isOutgoing) ? self.outgoingTextColor : self.incomingTextColor;
        
        if (backgroundColor == nil) {
            backgroundColor = [UIColor grayColor];
        }
        if (textColor == nil) {
            textColor = [UIColor whiteColor];
        }
        
        avatar = [[ZNGInitialsAvatar alloc] initWithInitials:initials textColor:textColor backgroundColor:backgroundColor size:self.avatarSize];
        [cache setObject:avatar forKey:uuid];
    }
    
    return avatar;
}

@end
