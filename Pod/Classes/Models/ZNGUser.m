//
//  ZNGUser.m
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import "ZNGUser.h"

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
             @"serviceIds" : @"service_ids"
             };
}

- (NSString *) fullName
{
    NSMutableString * name = nil;
    
    if (([self.firstName length] > 0) && ([self.lastName length] > 0)) {
        name = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    } else if ([self.firstName length] > 0) {
        name = self.firstName;
    } else if ([self.lastName length] > 0) {
        name = self.lastName;
    } else if ([self.username length] > 0) {
        name = self.username;
    }
    
    return name;
}

@end
