//
//  ZNGInboxDataClosed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataClosed.h"

@implementation ZNGInboxDataClosed

+ (NSString *) description
{
    return @"Closed conversation inbox data";
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsClosed] = ParameterValueTrue;
    
    return parameters;
}

@end
