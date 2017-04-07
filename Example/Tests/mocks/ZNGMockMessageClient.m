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
#import <ZingleSDK/ZNGNewMessageResponse.h>

@implementation ZNGMockMessageClient

- (void)sendMessage:(ZNGNewMessage*)newMessage
            success:(void (^)(ZNGNewMessageResponse * message, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure
{
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.alwaysFail) {
            if (failure) {
                failure(nil);
            }
        } else {
            NSUUID * messageUuid = [[NSUUID alloc] init];
            ZNGNewMessageResponse * response = [[ZNGNewMessageResponse alloc] init];
            response.messageIds = @[[messageUuid UUIDString]];
            
            self.lastSentMessageAttachments = newMessage.attachments;
            
            if (success) {
                success(response, status);
            }
        }
    });
}

@end
