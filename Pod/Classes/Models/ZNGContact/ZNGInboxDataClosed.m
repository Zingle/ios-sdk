//
//  ZNGInboxDataClosed.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataClosed.h"
#import "ZNGContact.h"

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

- (BOOL) contactBelongsInDataSet:(ZNGContact *)contact
{
    return contact.isClosed;
}

@end
