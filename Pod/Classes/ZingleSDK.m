//
//  ZingleSDK.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleSDK.h"
#import "ZNGLogging.h"
#import "ZingleAccountSession.h"
#import "ZingleContactSession.h"

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZingleSDK

+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue
{
    return [self contactSessionWithToken:token key:key channelTypeId:channelTypeId channelValue:channelValue contactServiceChooser:nil];
}

+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue contactServiceChooser:(nullable ZNGContactServiceChooser)contactServiceChooser
{
    return [[ZingleContactSession alloc] initWithToken:token key:key channelTypeId:channelTypeId channelValue:channelValue contactServiceChooser:contactServiceChooser];
}

+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token key:(NSString *)key
{
    return [self accountSessionWithToken:token key:key accountChooser:nil serviceChooser:nil];
}

+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token key:(NSString *)key accountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser
{
    return [[ZingleAccountSession alloc] initWithToken:token key:token accountChooser:accountChooser serviceChooser:serviceChooser];
}

@end
