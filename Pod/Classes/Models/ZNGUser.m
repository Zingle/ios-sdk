//
//  ZNGUser.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGUser.h"
#import "ZNGUserAuthorization.h"

@implementation ZNGUser

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"userId" : @"id",
             @"username" : @"username",
             @"email" : @"email",
             @"firstName" : @"first_name",
             @"lastName" : @"last_name",
             @"title" : @"title",
             @"serviceIds" : @"service_ids",
             @"avatarUri" : @"avatar_uri"
             };
}

- (BOOL) isEqual:(ZNGUser *)other
{
    if (![other isKindOfClass:[ZNGUser class]]) {
        return NO;
    }
    
    return ([self.userId isEqualToString:other.userId]);
}

- (NSUInteger) hash
{
    return [self.userId hash];
}

+ (NSValueTransformer *) avatarUriJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (NSString *) fullName
{
    NSMutableString * name = [[NSMutableString alloc] init];
    
    if ([self.firstName length] > 0) {
        [name appendString:self.firstName];
        [name appendString:@" "];
    }
    
    if ([self.lastName length] > 0) {
        [name appendString:self.lastName];
    }
    
    NSString * displayName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([displayName length] > 0) {
        return displayName;
    }
    
    if ([self.email length] > 0) {
        return self.email;
    }
    
    return nil;
}

+ (instancetype) userFromUserAuthorization:(ZNGUserAuthorization *)auth
{
    ZNGUser * user = [[self alloc] init];
    
    user.firstName = auth.firstName;
    user.lastName = auth.lastName;
    user.userId = auth.userId;
    user.email = auth.email;
    user.title = auth.title;
    user.serviceIds = auth.serviceIds;
    user.avatarUri = auth.avatarUri;
    
    return user;
}

+ (instancetype) userFromSocketData:(NSDictionary *)data
{
    ZNGUser * user = [[self alloc] init];
    
    id userIdUnknownType = data[@"id"];
    user.userId = ([userIdUnknownType isKindOfClass:[NSString class]]) ? userIdUnknownType : [userIdUnknownType stringValue];
    
    // Protect against these fields being NSNulls instead of NSStrings
    id firstNameOrNull = data[@"first_name"];
    id lastNameOrNull = data[@"last_name"];
    id emailOrNull = data[@"username"];
    user.firstName = ([firstNameOrNull isKindOfClass:[NSString class]]) ? firstNameOrNull : nil;
    user.lastName = ([lastNameOrNull isKindOfClass:[NSString class]]) ? lastNameOrNull : nil;
    user.email = ([emailOrNull isKindOfClass:[NSString class]]) ? emailOrNull : nil;
    
    // The avatar asset has been, at different times, a URI string and a dictionary with a "uri" key
    id avatarAsset = data[@"avatar_asset"];
    if ([avatarAsset isKindOfClass:[NSString class]]) {
        [user setValue:[NSURL URLWithString:avatarAsset] forKey:NSStringFromSelector(@selector(avatarUri))];
    } else if ([avatarAsset isKindOfClass:[NSDictionary class]]) {
        NSString * avatarUriString = avatarAsset[@"uri"];
        
        if ([avatarUriString isKindOfClass:[NSString class]]) {
            [user setValue:[NSURL URLWithString:avatarUriString] forKey:NSStringFromSelector(@selector(avatarUri))];
        }
    }
    
    return user;
}


@end
