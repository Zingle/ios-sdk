//
//  ZNGInboxDataOpen.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataOpen.h"

@implementation ZNGInboxDataOpen

+ (NSString *) description
{
    return @"Open conversation inbox data";
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsClosed] = ParameterValueFalse;
    
    return parameters;
}

@end
