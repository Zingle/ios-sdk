//
//  ZNGConversation.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZNGConversation.h"
#import "ZNGContact.h"
#import "ZNGService.h"
#import "ZNGMessageSearch.h"
#import "ZNGMessageCorrespondent.h"
#import "ZNGMessage.h"

@interface ZNGConversation()

@end

@implementation ZNGConversation

- (id)initWithService:(ZNGService *)service usingChannelType:(ZNGChannelType *)channelType;
{
    if( self = [super init]  ) {
        self.service = service;
        self.channelType = channelType;
    }
    return self;
}

- (void)toCorrespondant:(ZNGMessageCorrespondent *)to
{
    self.from = [[ZNGMessageCorrespondent alloc] init];
    [self.from setCorrespondent:self.service];
    
    self.to = to;
}

- (void)fromCorrespondant:(ZNGMessageCorrespondent *)from
{
    self.to = [[ZNGMessageCorrespondent alloc] init];
    [self.to setCorrespondent:self.service];
    
    self.from = from;
}

- (BOOL)isFromService
{
    if( self.from != nil ) {
        return [[self.from correspondentType] isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE];
    }
    
    return NO;
}

- (NSString *)messageDirectionFor:(ZNGMessage *)message
{
    NSString *direction = message.direction;
    if( ![self isFromService] ) {
        direction = ([direction isEqualToString:@"outbound"]) ? @"inbound" : @"outbound";
    }
    
    return direction;
}

- (NSArray *)messages
{
    ZNGMessageSearch *messageSearch = [[ZNGMessageSearch alloc] initWithService:self.service];
    return [messageSearch searchWithError:nil];
}

@end
