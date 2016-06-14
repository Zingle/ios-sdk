//
//  ZNGBaseClientService.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientService.h"
#import "ZNGService.h"

@implementation ZNGBaseClientService

- (instancetype) initWithAccount:(ZNGAccount *)account service:(ZNGService *)service
{
    self = [super initWithAccount:account];
    
    if (self != nil) {
        _service = service;
    }
    
    return self;
}

@end
