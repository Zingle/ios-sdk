//
//  ZNGInboxDataSearch.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSearch.h"

@implementation ZNGInboxDataSearch
{
    NSString * searchTerm;
}

- (nonnull instancetype) initWithServiceId:(nonnull NSString *)theServiceId searchTerm:(nonnull NSString *)theSearchTerm
{
    self = [super initWithServiceId:theServiceId];
    
    if (self != nil) {
        searchTerm = theSearchTerm;
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyQuery] = [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return parameters;
}

@end
