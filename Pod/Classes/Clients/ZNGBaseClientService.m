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

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session account:(nonnull ZNGAccount *)account service:(nonnull ZNGService *)service
{
    self = [super initWithSession:session account:account];
    
    if (self != nil) {
        _service = service;
    }
    
    return self;
}

@end
