//
//  ZNGInboxDataConfirmed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataConfirmed.h"

@implementation ZNGInboxDataConfirmed

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsConfirmed] = ParameterValueTrue;
    
    return parameters;
}

@end
