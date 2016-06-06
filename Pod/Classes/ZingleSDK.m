//
//  ZingleSDK.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleSDK.h"
#import <AFNetworking/AFNetworking.h>
#import "ZNGDataSet.h"
#import "ZNGServiceClient.h"
#import "ZNGContactClient.h"
#import "ZNGConversation.h"
#import "ZNGParticipant.h"
#import "ZNGContactChannelClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGUserAuthorization.h"

NSString *const zng_receivedPushNotification = @"zng_receivedPushNotification";
NSString *const zng_receivedPushNotificationInBackground = @"zng_receivedPushNotificationInBackground";
NSString *const zng_receivedPushNotificationInactive = @"zng_receivedPushNotificationInactive";

@interface ZingleSDK ()

@property(nonatomic, strong) AFHTTPSessionManager* sessionManager;

@end

@implementation ZingleSDK

NSString* const kLiveBaseURL = @"https://api.zingle.me/v1/";
NSString* const kDebugBaseURL = @"https://ci-api.zingle.me/v1/";
NSString* const kAllowedChannelTypeClass = @"UserDefinedChannel";

+ (ZingleSDK*)sharedSDK
{
    static ZingleSDK* sharedSDK = nil;
    static dispatch_once_t sdkOnceToken;
    
    dispatch_once(&sdkOnceToken, ^{
        sharedSDK = [[ZingleSDK alloc] init];
    });
    
    return sharedSDK;
}

- (void)setToken:(NSString*)token andKey:(NSString*)key
{
    [self setToken:token andKey:key forDebugMode:NO];
}

- (void)setToken:(NSString *)token andKey:(NSString *)key forDebugMode:(BOOL)debugMode
{
    if (token == nil || key == nil) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    NSString *baseURL = debugMode ? kDebugBaseURL : kLiveBaseURL;
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
    [self.sessionManager.requestSerializer setValue:@"iOS_SDK" forHTTPHeaderField:@"Zingle_Agent"];
}

- (void)checkAuthorizationForContactService:(ZNGContactService *)contactService
                                    success:(void (^)(BOOL isAuthorized))success
                                    failure:(void (^)(ZNGError* error))failure
{
    [ZNGUserAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization *userAuthorization, ZNGStatus *status) {
        
        if (userAuthorization) {
            
            if ([userAuthorization.authorizationClass isEqualToString:@"contact"]) {
                [self.sessionManager.requestSerializer setValue:contactService.contactId forHTTPHeaderField:@"x-zingle-contact-id"];
            } else {
                [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"x-zingle-contact-id"];
            }
            
            success(true);
        } else {
            success(false);
        }
    
    } failure:^(ZNGError *error) {
        failure(error);
    }];
    
}

- (void)addConversationFromContact:(ZNGContact *)contact
                         toService:(ZNGService *)service
                           success:(void (^)(ZNGConversation* conversation))success
                           failure:(void (^)(ZNGError* error))failure
{
    [self addConversationToService:YES withService:service contact:contact success:success failure:failure];
}

- (void)addConversationFromService:(ZNGService *)service
                         toContact:(ZNGContact *)contact
                           success:(void (^)(ZNGConversation* conversation))success
                           failure:(void (^)(ZNGError* error))failure
{
    [self addConversationToService:NO withService:service contact:contact success:success failure:failure];
}

- (void)addConversationToService:(BOOL)toService
                     withService:(ZNGService *)service
                         contact:(ZNGContact *)contact
                         success:(void (^)(ZNGConversation* conversation))success
                         failure:(void (^)(ZNGError* error))failure
{
    ZNGConversation *conversation = [[ZNGConversation alloc] init];
    conversation.toService = toService;
    conversation.contactId = contact.contactId;
    conversation.serviceId = service.serviceId;
    
    if (toService) {
        [[ZNGDataSet sharedDataSet] addConversation:conversation toServiceId:service.serviceId];
    } else {
        [[ZNGDataSet sharedDataSet] addConversation:conversation toContactId:contact.contactId];
    }
    if (success) {
        success(conversation);
    }
}

- (void)addConversationToService:(BOOL)toService
                     withService:(ZNGService *)service
                         contact:(ZNGContact *)contact
                     channelType:(ZNGChannelType *)channelType
             contactChannelValue:(NSString *)contactChannelValue
                         success:(void (^)(ZNGConversation* conversation))success
                         failure:(void (^)(ZNGError* error))failure
{
    ZNGConversation *conversation = [[ZNGConversation alloc] init];
    conversation.toService = toService;
    conversation.contactId = contact.contactId;
    conversation.serviceId = service.serviceId;
    conversation.channelType = channelType;
    conversation.contactChannelValue = contactChannelValue;
    
    if (toService) {
        [[ZNGDataSet sharedDataSet] addConversation:conversation toServiceId:service.serviceId];
    } else {
        [[ZNGDataSet sharedDataSet] addConversation:conversation toContactId:contact.contactId];
    }
    if (success) {
        success(conversation);
    }
}

- (ZNGConversation *)conversationToService:(NSString *)serviceId
{
    return [[ZNGDataSet sharedDataSet] getConversationToServiceId:serviceId];
}

- (ZNGConversation *)conversationToContact:(NSString *)contactId
{
    return [[ZNGDataSet sharedDataSet] getConversationToContactId:contactId];
}

- (void)clearCachedConversations
{
    [[ZNGDataSet sharedDataSet] clearConversations];
}

- (ZNGConversationViewController *)conversationViewControllerToService:(ZNGService *)service
                                                               contact:(ZNGContact *)contact
                                                            senderName:(NSString *)senderName
                                                          receiverName:(NSString *)receiverName
{
    return [ZNGConversationViewController toService:service contact:contact senderName:senderName receiverName:receiverName];
}

- (ZNGConversationViewController *)conversationViewControllerToContact:(ZNGContact *)contact
                                                               service:(ZNGService *)service
                                                            senderName:(NSString *)senderName
                                                          receiverName:(NSString *)receiverName
{
    return [ZNGConversationViewController toContact:contact service:service senderName:senderName receiverName:receiverName];
}

- (AFHTTPSessionManager*)sharedSessionManager
{
    if (!self.sessionManager) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    
    return self.sessionManager;
}

@end
