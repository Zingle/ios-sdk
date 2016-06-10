//
//  ZNGInboxDataClosed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataClosed.h"

@implementation ZNGInboxDataClosed

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsConfirmed] = ParameterValueFalse;
    
    return parameters;
}

@end
