//
//  ZNGBaseClientService.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientService.h"

@class ZNGAccount;

@implementation ZNGBaseClientService

- (instancetype) initWithSession:(__weak ZingleSession *)session serviceId:(NSString *)serviceId;
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        _serviceId = serviceId;
    }
    
    return self;
}

@end
