//
//  ZNGContactDataSetBuilder.m
//  Pods
//
//  Created by Jason Neel on 4/25/17.
//
//

#import "ZNGContactDataSetBuilder.h"
#import "ZNGInboxDataSet.h"
#import "ZingleAccountSession.h"
#import "ZNGLabel.h"
#import "ZNGContactGroup.h"

@implementation ZNGContactDataSetBuilder

- (ZNGInboxDataSet *)build
{
    return [[ZNGInboxDataSet alloc] initWithBuilder:self];
}

- (void) setBaseDataSet:(ZNGInboxDataSet *)baseDataSet
{
    _baseDataSet = baseDataSet;
    
    self.pageSize = baseDataSet.pageSize;
    self.openStatus = baseDataSet.openStatus;
    self.unconfirmed = baseDataSet.unconfirmed;
    self.labelIds = baseDataSet.labelIds;
    self.groupIds = baseDataSet.groupIds;
    self.unassigned = baseDataSet.unassigned;
    self.assignedUserId = baseDataSet.assignedUserId;
    self.assignedTeamId = baseDataSet.assignedTeamId;
    self.searchText = baseDataSet.searchText;
    self.searchMessageBodies = baseDataSet.searchMessageBodies;
    self.allowContactsWithNoMessages = baseDataSet.allowContactsWithNoMessages;
    
    if ([baseDataSet.sortFields count] > 0) {
        self.sortFields = baseDataSet.sortFields;
    }
    
    if (baseDataSet.contactClient != nil) {
        self.contactClient = baseDataSet.contactClient;
    }
}

+ (NSDictionary *) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(pageSize)): NSStringFromSelector(@selector(pageSize)),
             NSStringFromSelector(@selector(openStatus)): NSStringFromSelector(@selector(openStatus)),
             NSStringFromSelector(@selector(unconfirmed)): NSStringFromSelector(@selector(unconfirmed)),
             NSStringFromSelector(@selector(allowContactsWithNoMessages)): NSStringFromSelector(@selector(allowContactsWithNoMessages)),
             NSStringFromSelector(@selector(sortFields)): NSStringFromSelector(@selector(sortFields)),
             NSStringFromSelector(@selector(labelIds)): NSStringFromSelector(@selector(labelIds)),
             NSStringFromSelector(@selector(groupIds)): NSStringFromSelector(@selector(groupIds)),
             NSStringFromSelector(@selector(unassigned)): NSStringFromSelector(@selector(unassigned)),
             NSStringFromSelector(@selector(assignedTeamId)): NSStringFromSelector(@selector(assignedTeamId)),
             NSStringFromSelector(@selector(assignedUserId)): NSStringFromSelector(@selector(assignedUserId)),
             NSStringFromSelector(@selector(searchText)): NSStringFromSelector(@selector(searchText)),
             NSStringFromSelector(@selector(searchMessageBodies)): NSStringFromSelector(@selector(searchMessageBodies)),
             };
}

- (BOOL) builderCanBeUsedForSession:(ZingleAccountSession *)session
{
    if (self.unassigned) {
        if (![session.service allowsAssignment]) {
            return NO;
        }
    }
    
    if ([self.assignedUserId length] > 0) {
        if (![session.service allowsAssignment]) {
            return NO;
        }
        
        if ([session userWithId:self.assignedUserId] == nil) {
            return NO;
        }
    }
    
    if ([self.assignedTeamId length] > 0) {
        if (![session.service allowsTeamAssignment]) {
            return NO;
        }
        
        if ([session.service teamWithId:self.assignedTeamId] == nil) {
            return NO;
        }
    }
    
    for (NSString * labelId in self.labelIds) {
        NSUInteger matchingLabelIndex = [session.service.contactLabels indexOfObjectPassingTest:^BOOL(ZNGLabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return ([obj.labelId isEqualToString:labelId]);
        }];
        
        if (matchingLabelIndex == NSNotFound) {
            return NO;
        }
    }
    
    for (NSString * groupId in self.groupIds) {
        NSUInteger matchingGroupIndex = [session.service.contactGroups indexOfObjectPassingTest:^BOOL(ZNGContactGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return ([obj.groupId isEqualToString:groupId]);
        }];
        
        if (matchingGroupIndex == NSNotFound) {
            return NO;
        }
    }
    
    return YES;
}

@end
