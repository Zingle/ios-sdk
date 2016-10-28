//
//  ZNGMockUserAuthorizationClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockUserAuthorizationClient.h"
#import "ZingleSDK/ZNGContact.h"
#import "ZingleSDK/ZNGStatus.h"

@implementation ZNGMockUserAuthorizationClient

- (id) initWithSession:(ZingleSession * _Nonnull __weak)session
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        _authorizationClass = @"contact";
    }
    
    return self;
}

- (void)userAuthorizationWithSuccess:(void (^)(ZNGUserAuthorization* userAuthorization, ZNGStatus* status))success
                             failure:(void (^)(ZNGError* error))failure
{
    if (success == nil) {
        return;
    }
    
    ZNGUserAuthorization * auth = [[ZNGUserAuthorization alloc] init];
    auth.authorizationClass = self.authorizationClass;
    auth.firstName = [[self.contact firstNameFieldValue] value];
    auth.lastName = [[self.contact lastNameFieldValue] value];
    auth.title = [[self.contact titleFieldValue] value];
    auth.userId = self.contact.contactId;
    
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    status.page = 1;
    status.totalPages = 1;
    status.totalRecords = 1;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        success(auth, status);
    });
}

@end
