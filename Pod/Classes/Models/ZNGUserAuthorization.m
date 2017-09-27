//
//  ZNGUserAuthorization.m
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import "ZNGUserAuthorization.h"
#import "ZNGUser.h"

@implementation ZNGUserAuthorization

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"authorizationClass" : @"authorization_class",
             NSStringFromSelector(@selector(userId)) : @"id",
             @"email" : @"email",
             @"firstName" : @"first_name",
             @"lastName" : @"last_name",
             @"title" : @"title",
             NSStringFromSelector(@selector(accountIds)): @"account_uuids",
             NSStringFromSelector(@selector(serviceIds)): @"service_uuids",
             NSStringFromSelector(@selector(avatarUri)): @"avatar_uri",
             };
}

+ (NSValueTransformer *) avatarUriJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (NSString *)displayName
{
    return [[ZNGUser userFromUserAuthorization:self] fullName];
}

@end
