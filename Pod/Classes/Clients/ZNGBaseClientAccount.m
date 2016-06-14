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

- (instancetype) initWithAccount:(ZNGAccount *)account
{
    self = [super init];
    
    if (self != nil) {
        _account = account;
    }
    
    return self;
}

@end
