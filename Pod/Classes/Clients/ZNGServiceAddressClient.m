//
//  ZNGServiceAddressClient.m
//  Pods
//
//  Created by Ryan Farley on 2/4/16.
//
//

#import "ZNGServiceAddressClient.h"

@implementation ZNGServiceAddressClient

#pragma mark - ZNGClientProtocol

+ (Class)responseObject
{
  return [ZNGServiceAddressClient class];
}

@end
