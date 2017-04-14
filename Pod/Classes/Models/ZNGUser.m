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
    
    NSString * displayName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([displayName length] > 0) {
        return displayName;
    }
    
    if ([self.email length] > 0) {
        return self.email;
    }
    
    return @"Someone";
}

+ (instancetype) userFromUserAuthorization:(ZNGUserAuthorization *)auth
{
    ZNGUser * user = [[self alloc] init];
    
    user.firstName = auth.firstName;
    user.lastName = auth.lastName;
    user.userId = auth.userId;
    user.email = auth.email;
    user.title = auth.title;
    
    return user;
}

@end
