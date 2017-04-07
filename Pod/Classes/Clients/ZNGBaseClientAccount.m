//
//  ZNGBaseClientAccount.m
//  Pods
//
//  Created by Jason Neel on 4/6/17.
//
//

#import "ZNGBaseClientAccount.h"

@implementation ZNGBaseClientAccount

- (id) initWithSession:(ZingleSession * _Nonnull __weak)session accountId:(NSString *)accountId
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        _accountId = [accountId copy];
    }
    
    return self;
}

@end
