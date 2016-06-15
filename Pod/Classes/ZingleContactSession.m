//
//  ZingleContactSession.m
//  Pods
//
//  Created by Jason Neel on 6/15/16.
//
//

#import "ZingleContactSession.h"

@implementation ZingleContactSession

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        _channelTypeID = [channelTypeId copy];
        _channelValue = [channelValue copy];
    }
    
    return self;
}

@end
