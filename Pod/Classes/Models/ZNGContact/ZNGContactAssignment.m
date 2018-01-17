//
//  ZNGContactAssignment.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/16/18.
//

#import "ZNGContactAssignment.h"

@implementation ZNGContactAssignment

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(teamId)): @"team_id",
             NSStringFromSelector(@selector(userId)): @"user_id",
             };
}

@end
