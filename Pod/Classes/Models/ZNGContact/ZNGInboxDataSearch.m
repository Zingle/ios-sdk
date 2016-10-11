//
//  ZNGInboxDataSearch.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSearch.h"
#import "ZNGLogging.h"
#import "ZNGContact.h"
#import "ZNGLabel.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGInboxDataSearch

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
        _onlyContactsWithMessages = YES;
        _searchTerm = [theSearchTerm copy];
        
        if ([targetInbox isKindOfClass:[ZNGInboxDataSearch class]]) {
            ZNGLogInfo(@"Search inbox data set is being initialized with a previous search inbox data set.  The old search terms will be erased, but other parameters will be retained.");
            
            ZNGInboxDataSearch * oldSearchData = (ZNGInboxDataSearch *)targetInbox;
            _onlyContactsWithMessages = oldSearchData.onlyContactsWithMessages;
            _searchMessageBodies = oldSearchData.searchMessageBodies;
        }
        
        _targetInbox = targetInbox;
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    [[self.targetInbox parameters] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        parameters[key] = obj;
    }];
    
    if ([_searchTerm length] > 0) {
        parameters[ParameterKeyQuery] = [_searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        [parameters removeObjectForKey:ParameterKeyQuery];
    }
    
    if (self.searchMessageBodies) {
        parameters[ParameterKeySearchMessageBodies] = ParameterValueTrue;
    }
    
    // The default inbox parameters specify message created at > 0.  If we are also searching those with no messages, we will remove this parameter.
    if (!self.onlyContactsWithMessages) {
        [parameters removeObjectForKey:ParameterKeyLastMessageCreatedAt];
    }
    
    return parameters;
}

// It is not expected for this method to be used for this particular data set.  We'll take a quick shot at getting things close instead of just being lazy and returning YES.
- (BOOL) contactBelongsInDataSet:(ZNGContact *)contact
{
    NSMutableString * allSearchableFields = [[contact fullName] mutableCopy];
    
    for (ZNGLabel * label in contact.labels) {
        if (label.displayName != nil) {
            [allSearchableFields appendString:label.displayName];
        }
    }
    
    if ((self.searchMessageBodies) && (contact.lastMessage.body != nil)) {
        [allSearchableFields appendString:contact.lastMessage.body];
    }
    
    return [[allSearchableFields lowercaseString] containsString:[self.searchTerm lowercaseString]];
}

@end
