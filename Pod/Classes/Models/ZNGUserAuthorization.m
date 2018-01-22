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
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                            NSStringFromSelector(@selector(authorizationClass)): @"authorization_class",
                                                                                            }];
}

- (NSString *)displayName
{
    return [super fullName];
}

@end
