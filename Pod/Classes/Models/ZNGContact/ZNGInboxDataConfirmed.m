//
//  ZNGInboxDataConfirmed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataConfirmed.h"
#import "ZNGContact.h"

@implementation ZNGInboxDataConfirmed

+ (NSString *) description
{
    return @"Confirmed conversation inbox data";
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyIsConfirmed] = ParameterValueTrue;
    
    return parameters;
}

- (BOOL) contactBelongsInDataSet:(ZNGContact *)contact
{
    return contact.isConfirmed;
}

@end
