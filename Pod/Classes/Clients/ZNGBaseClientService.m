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

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session account:(nonnull ZNGAccount *)account serviceId:(nonnull NSString *)serviceId
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        _serviceId = serviceId;
    }
    
    return self;
}

@end
