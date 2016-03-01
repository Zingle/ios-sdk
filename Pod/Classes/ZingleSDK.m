//
//  ZingleSDK.m
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import "ZingleSDK.h"
#import "ZNGConstants.h"
#import "ZNGDataSet.h"
#import "ZNGServiceClient.h"
#import "ZNGContactClient.h"
#import "ZNGConversation.h"
#import "ZNGParticipant.h"
#import "ZNGContactChannelClient.h"

@interface ZingleSDK ()

@property(nonatomic, strong) AFHTTPSessionManager* sessionManager;

@end

@implementation ZingleSDK

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
    if (token == nil || key == nil) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kQABaseURL]];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:token password:key];
}

- (void)addConversationWithServiceId:(NSString *)serviceId
                           contactId:(NSString *)contactId
                 contactChannelValue:(NSString *)contactChannelValue
                             success:(void (^)(ZNGConversation* conversation))success
                             failure:(void (^)(ZNGError* error))failure
{
    [ZNGServiceClient serviceWithId:serviceId success:^(ZNGService *service, ZNGStatus* status) {

        [[ZNGDataSet sharedDataSet] addService:service];
        
        [ZNGContactClient contactWithId:contactId withServiceId:serviceId success:^(ZNGContact *contact, ZNGStatus* status) {
            
            [[ZNGDataSet sharedDataSet] addContact:contact];
            
            ZNGConversation *conversation = [[ZNGConversation alloc] init];
            
            ZNGParticipant *contactParticipant = [[ZNGParticipant alloc] init];
            contactParticipant.type = ZNGParticipantTypeContact;
            contactParticipant.participantId = contactId;
            contactParticipant.channelValue = contactChannelValue;
            
            conversation.contact = contactParticipant;
            
            ZNGParticipant *serviceParticipant = [[ZNGParticipant alloc] init];
            serviceParticipant.type = ZNGParticipantTypeService;
            serviceParticipant.participantId = serviceId;
            serviceParticipant.name = service.displayName;
            
            conversation.service = serviceParticipant;
            
            NSString *allowedChannelTypeClass = @"UserDefinedChannel";
            for (ZNGChannel *channel in contact.channels) {
                
                if ([channel.channelType.typeClass isEqualToString:allowedChannelTypeClass]) {
                    conversation.channelTypeId = channel.channelType.channelTypeId;
                }
            }
            
            if (conversation.channelTypeId == nil) {
                for (ZNGChannelType *channelType in service.channelTypes) {
                    
                    if ([channelType.typeClass isEqualToString:allowedChannelTypeClass]) {
                        conversation.channelTypeId = channelType.channelTypeId;
                    }
                }
                if (conversation.channelTypeId == nil) {
                    NSLog(@"Service %@ (id=%@) does not support user defined channels.", service.displayName, service.serviceId);
                    return;
                }
                
                ZNGNewContactChannel *newChannel = [[ZNGNewContactChannel alloc] init];
                newChannel.channelTypeId = conversation.channelTypeId;
                newChannel.value = contactChannelValue;
                
                [ZNGContactChannelClient saveContactChannel:newChannel withContactId:contact.contactId withServiceId:serviceId success:^(ZNGContactChannel *contactChannel, ZNGStatus *status) {
                    [[ZNGDataSet sharedDataSet] addConversation:conversation];
                    if (success) {
                        success(conversation);
                    }
                } failure:failure];
            
            } else {
                [[ZNGDataSet sharedDataSet] addConversation:conversation];
                if (success) {
                    success(conversation);
                }
            }
        } failure:failure];
    } failure:failure];
}

- (ZNGConversationViewController *)conversationViewControllerForConversation:(ZNGConversation *)conversation
{
    return [[ZNGConversationViewController alloc] initWithConversation:conversation];
}

- (AFHTTPSessionManager*)sharedSessionManager
{
    if (!self.sessionManager) {
        [NSException raise:NSInvalidArgumentException format:@"ZingleSDK must be initialized with a token and key."];
    }
    
    return self.sessionManager;
}

@end
