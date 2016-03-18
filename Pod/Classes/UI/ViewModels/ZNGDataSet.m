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
        sharedDataSet.conversations = [[NSMutableDictionary alloc] init];
    });
    
    return sharedDataSet;
}

- (void)addConversation:(ZNGConversation *)conversation toServiceId:(NSString *)serviceId
{
    [self.conversations setObject:conversation forKey:serviceId];
    [conversation updateMessages];
}

- (void)addConversation:(ZNGConversation *)conversation toContactId:(NSString *)contactId
{
    [self.conversations setObject:conversation forKey:contactId];
    [conversation updateMessages];
}

- (ZNGConversation *)getConversationToServiceId:(NSString *)serviceId
{
    return [self.conversations objectForKey:serviceId];
}

- (ZNGConversation *)getConversationToContactId:(NSString *)contactId
{
    return [self.conversations objectForKey:contactId];
}

@end
