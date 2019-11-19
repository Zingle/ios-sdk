//
//  ZingleSDK.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleSDK.h"
#import "ZingleAccountSession.h"
#import "ZingleContactSession.h"

NSString * const ZNGPushNotificationReceived = @"ZNGPushNotificationReceived";

@implementation ZingleSDK

+ (void) setPushNotificationDeviceToken:(nonnull NSData *)token
{
    [ZingleSession setPushNotificationDeviceToken:token];
}

+ (void) setFirebaseToken:(nonnull NSString *)token
{
    [ZingleSession setFirebaseToken:token];
}

+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue
{
    return [[ZingleContactSession alloc] initWithToken:token key:key channelTypeId:channelTypeId channelValue:channelValue];
}

+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token key:(NSString *)key
{
    return [[ZingleAccountSession alloc] initWithToken:token key:key];
}

@end
