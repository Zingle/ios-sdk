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

- (id) initWithServiceId:(NSString *)theServiceId searchTerm:(NSString *)theSearchTerm
{
    self = [super initWithServiceId:theServiceId];
    
    if (self != nil) {
        searchTerm = theSearchTerm;
    }
    
    return self;
}

- (NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyQuery] = [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return parameters;
}

@end
