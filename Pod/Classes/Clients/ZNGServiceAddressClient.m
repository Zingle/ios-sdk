//
//  ZNGServiceAddressClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGServiceAddressClient.h"
#import "ZNGConstants.h"

@implementation ZNGServiceAddressClient

#pragma mark - ZNGClientProtocol

+ (Class)responseObject
{
    return [ZNGServiceAddressClient class];
}

+ (NSString *)resourcePath
{
    return kServiceResourcePath;
}

@end
