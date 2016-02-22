//
//  ZNGDataSet.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGDataSet.h"

@interface ZNGDataSet ()

@property (nonatomic, strong) NSMutableDictionary* services;
@property (nonatomic, strong) NSMutableDictionary* contacts;
@property (nonatomic, strong) NSMutableDictionary* conversations;

@end

@implementation ZNGDataSet

+ (instancetype)sharedDataSet
{
    static ZNGDataSet* sharedDataSet = nil;
    static dispatch_once_t sdsOnceToken;
    
    dispatch_once(&sdsOnceToken, ^{
        sharedDataSet = [[ZNGDataSet alloc] init];
        sharedDataSet.services = [[NSMutableDictionary alloc] init];
        sharedDataSet.contacts = [[NSMutableDictionary alloc] init];
    });
    
    return sharedDataSet;
}

- (void)addService:(ZNGService *)service
{
    [self.services setObject:service forKey:service.serviceId];
}

- (void)addContact:(ZNGContact *)contact
{
    [self.contacts setObject:contact forKey:contact.contactId];
}

- (void)addConversation:(ZNGConversation *)conversation
{
    [self.conversations setObject:conversation forKey:conversation.service.participantId];
    [conversation updateMessages];
}

- (ZNGConversation *)getConversationWithServiceId:(NSString *)serviceId
{
    return [self.conversations objectForKey:serviceId];
}

@end
