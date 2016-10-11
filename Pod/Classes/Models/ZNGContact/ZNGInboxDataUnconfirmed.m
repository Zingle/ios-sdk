//
//  ZNGInboxDataUnconfirmed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataUnconfirmed.h"
#import "ZNGContact.h"

@implementation ZNGInboxDataUnconfirmed

+ (NSString *) description
{
    return @"Unconfirmed conversation inbox data";
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsConfirmed] = ParameterValueFalse;
    
    return parameters;
}

- (BOOL) contactBelongsInDataSet:(ZNGContact *)contact
{
    return !(contact.isConfirmed);
}

@end
