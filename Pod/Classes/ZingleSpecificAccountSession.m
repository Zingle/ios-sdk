//
//  ZingleSpecificAccountSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleSpecificAccountSession.h"

@implementation ZingleSpecificAccountSession

- (instancetype) initWithToken:(NSString *)token key:(NSString *)key account:(ZNGAccount *)account service:(ZNGService *)service
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        _account = account;
        _service = service;
    }
    
    return self;
}

@end
