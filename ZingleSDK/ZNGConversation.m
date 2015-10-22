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

@interface ZNGConversation()

@end

@implementation ZNGConversation

- (id)initWithFrom:(ZNGMessageCorrespondent *)from to:(ZNGMessageCorrespondent *)to usingChannelType:(ZNGChannelType *)channelType;
{
    if( self = [super init]  ) {
        self.from = from;
        self.to = to;
        self.channelType = channelType;
    }
    return self;
}

- (NSArray *)messages
{
    ZNGMessageSearch *messageSearch = [[ZNGMessageSearch alloc] init];
    
}

@end
