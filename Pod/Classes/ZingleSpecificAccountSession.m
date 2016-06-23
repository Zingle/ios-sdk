//
//  ZingleSpecificAccountSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSpecificAccountSession.h"
#import "ZingleAccountSession.h"
#import "ZNGAutomationClient.h"
#import "ZNGContactChannelClient.h"
#import "ZNGContactClient.h"
#import "ZNGLabelClient.h"
#import "ZNGMessageClient.h"
#import "ZNGTemplateClient.h"

@implementation ZingleSpecificAccountSession
{
    __weak ZingleAccountSession * accountSession;
}

- (nonnull instancetype) initWithAccountSession:(nonnull __weak ZingleAccountSession *)anAccountSession serviceId:(nonnull NSString *)serviceId;
{
    self = [super initWithToken:anAccountSession.token key:anAccountSession.key];
    
    if (self != nil) {
        accountSession = anAccountSession;
        
        self.automationClient = [[ZNGAutomationClient alloc] initWithSession:self serviceId:serviceId];
        self.contactChannelClient = [[ZNGContactChannelClient alloc] initWithSession:self serviceId:serviceId];
        self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
        self.labelClient = [[ZNGLabelClient alloc] initWithSession:self serviceId:serviceId];
        self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
        
        [self _registerForPushNotificationsForServiceIds:@[serviceId] removePreviousSubscriptions:YES];
    }
    
    return self;
}

- (AFHTTPSessionManager *) sessionManager
{
    return accountSession.sessionManager;
}

- (dispatch_queue_t) jsonProcessingQueue
{
    return accountSession.jsonProcessingQueue;
}

@end
