//
//  ZNGInboxDataSearch.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSearch.h"

@implementation ZNGInboxDataSearch

- (nonnull instancetype) initWithContactClient:(ZNGContactClient *)contactClient searchTerm:(nonnull NSString *)theSearchTerm;
{
    self = [super initWithContactClient:contactClient];
    
    if (self != nil) {
        _searchTerm = [theSearchTerm copy];
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyQuery] = [_searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return parameters;
}

@end
