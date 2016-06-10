//
//  ZNGInboxDataStarred.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataStarred.h"

@implementation ZNGInboxDataStarred

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsStarred] = ParameterValueTrue;
    
    return parameters;
}

@end
