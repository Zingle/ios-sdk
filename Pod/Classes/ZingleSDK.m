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

NSString * const ZNGPushNotificationReceived = @"ZNGPushNotificationReceived";

@implementation ZingleSDK

+ (void) setPushNotificationDeviceToken:(nonnull NSData *)token
{
    [ZingleSession setPushNotificationDeviceToken:token];
}

+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue
{
    return [self contactSessionWithToken:token key:key channelTypeId:channelTypeId channelValue:channelValue contactServiceChooser:nil errorHandler:nil];
}

+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue contactServiceChooser:(nullable ZNGContactServiceChooser)contactServiceChooser errorHandler:(ZNGErrorHandler)errorHandler
{
    return [[ZingleContactSession alloc] initWithToken:token key:key channelTypeId:channelTypeId channelValue:channelValue contactServiceChooser:contactServiceChooser errorHandler:errorHandler];
}

+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token key:(NSString *)key errorHandler:(ZNGErrorHandler)errorHandler
{
    return [self accountSessionWithToken:token key:key accountChooser:nil serviceChooser:nil errorHandler:errorHandler];
}

+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token
                                               key:(NSString *)key
                                    accountChooser:(nullable ZNGAccountChooser)accountChooser
                                    serviceChooser:(nullable ZNGServiceChooser)serviceChooser
                                      errorHandler:(ZNGErrorHandler)errorHandler
{
    return [[ZingleAccountSession alloc] initWithToken:token key:token accountChooser:accountChooser serviceChooser:serviceChooser errorHandler:errorHandler];
}

@end
