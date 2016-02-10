//
//  ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface ZingleSDK : NSObject

// Initialization
+ (instancetype)sharedSDK;
- (void)setToken:(NSString*)token andKey:(NSString*)key;

- (AFHTTPSessionManager*)sharedSessionManager;

@end
