//
//  ZNGMockMessageClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import "ZNGMockMessageClient.h"
#import <ZingleSDK/ZNGNewMessage.h>
#import <ZingleSDK/ZNGStatus.h>

@implementation ZNGMockMessageClient

- (void)sendMessage:(ZNGNewMessage*)newMessage
            success:(void (^)(ZNGNewMessageResponse * message, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    self.lastSentMessageAttachments = newMessage.attachments;
    
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        success(nil, status);
    });
}

@end
