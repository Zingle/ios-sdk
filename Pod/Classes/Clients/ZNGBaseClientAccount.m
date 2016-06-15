//
//  ZNGBaseClientAccount.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientAccount.h"
#import "ZNGAccount.h"

@implementation ZNGBaseClientAccount

- (nonnull instancetype) initWithSession:(ZingleSession * _Nonnull __weak)session account:(nonnull ZNGAccount *)account
{
    self = [super initWithSession:session];
    
    if (self != nil) {
        _account = account;
    }
    
    return self;
}

@end
