//
//  ZNGInboxDataSearch.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSearch.h"

@implementation ZNGInboxDataSearch

+ (NSString *) description
{
    return @"Inbox data by search result";
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: %@ %p", [self class], self.searchTerm, self];
}

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
    
    if ([_searchTerm length] > 0) {
        parameters[ParameterKeyQuery] = [_searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    return parameters;
}

@end
