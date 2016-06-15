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

- (nonnull instancetype) initWithAccountSession:(nonnull __weak ZingleAccountSession *)anAccountSession account:(nonnull ZNGAccount *)account service:(nonnull ZNGService *)service
{
    self = [super initWithToken:accountSession.token key:accountSession.key];
    
    if (self != nil) {
        accountSession = anAccountSession;
        _account = account;
        _service = service;
        
        self.automationClient = [[ZNGAutomationClient alloc] initWithSession:self account:_account service:_service];
        self.contactChannelClient = [[ZNGContactChannelClient alloc] initWithSession:self account:_account service:_service];
        self.contactClient = [[ZNGContactClient alloc] initWithSession:self account:_account service:_service];
        self.labelClient = [[ZNGLabelClient alloc] initWithSession:self account:_account service:_service];
        self.messageClient = [[ZNGMessageClient alloc] initWithSession:self account:_account service:_service];
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
