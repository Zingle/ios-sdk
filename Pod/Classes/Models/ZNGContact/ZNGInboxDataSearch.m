//
//  ZNGInboxDataSearch.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSearch.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGInboxDataSearch
{
    NSDictionary * targetParameters;
}

+ (NSString *) description
{
    return @"Inbox data by search result";
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: %@ %p>", [self class], self.searchTerm, self];
}

- (instancetype) initWithContactClient:(ZNGContactClient *)contactClient searchTerm:(NSString *)theSearchTerm targetInboxData:(ZNGInboxDataSet * __nullable)targetInbox;
{
    self = [super initWithContactClient:contactClient];
    
    if (self != nil) {
        _searchTerm = [theSearchTerm copy];
        
        if ([targetInbox isKindOfClass:[ZNGInboxDataSearch class]]) {
            ZNGLogWarn(@"Search inbox data set is being initialized with a previous search inbox data set.  The old search terms will be erased, but other parameters will be retained.");
        }
        
        targetParameters = [targetInbox parameters];
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    [targetParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        parameters[key] = obj;
    }];
    
    if ([_searchTerm length] > 0) {
        parameters[ParameterKeyQuery] = [_searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    return parameters;
}

@end
