//
//  ZingleSpecificAccountSession.h
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSession.h"

@class ZNGAccount;
@class ZingleAccountSession;
@class ZNGService;
@class ZNGAutomationClient, ZNGContactChannelClient, ZNGContactClient, ZNGLabelClient, ZNGMessageClient, ZNGTemplateClient;

/*
 *  Private subclass of ZingleAccountSession that will always have session and account information available.
 *
 *  Should only be accessed through a ZingleAccountSession object.
 */
@interface ZingleSpecificAccountSession : ZingleSession

@property (nonatomic, readonly, nonnull) ZNGAccount * account;
@property (nonatomic, readonly, nonnull) ZNGService * service;

@property (nonatomic, strong, nonnull) ZNGAutomationClient * automationClient;
@property (nonatomic, strong, nonnull) ZNGContactChannelClient * contactChannelClient;
@property (nonatomic, strong, nonnull) ZNGContactClient * contactClient;
@property (nonatomic, strong, nonnull) ZNGLabelClient * labelClient;
@property (nonatomic, strong, nonnull) ZNGTemplateClient * templateClient;

- (nonnull instancetype) initWithAccountSession:(nonnull __weak ZingleAccountSession *)accountSession account:(nonnull ZNGAccount *)account service:(nonnull ZNGService *)service;

@end
