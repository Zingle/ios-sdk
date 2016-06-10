//
//  ZNGInboxDataUnconfirmed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataUnconfirmed.h"

@implementation ZNGInboxDataUnconfirmed

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsConfirmed] = ParameterValueFalse;
    
    return parameters;
}

@end
