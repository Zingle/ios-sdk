//
//  ZNGUserAuthorization.m
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import "ZNGUserAuthorization.h"

@implementation ZNGUserAuthorization

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"authorizationClass" : @"authorization_class",
             @"userId" : @"id",
             @"email" : @"email",
             @"firstName" : @"first_name",
             @"lastName" : @"last_name",
             @"title" : @"title"
             };
}

- (NSString *)displayName
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

@end
