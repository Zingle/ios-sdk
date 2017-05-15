//
//  ZNGContactDataSetBuilder.m
//  Pods
//
//  Created by Jason Neel on 4/25/17.
//
//

#import "ZNGContactDataSetBuilder.h"
#import "ZNGInboxDataSet.h"

@implementation ZNGContactDataSetBuilder

- (ZNGInboxDataSet *)build
{
    return [[ZNGInboxDataSet alloc] initWithBuilder:self];
}

- (void) setBaseDataSet:(ZNGInboxDataSet *)baseDataSet
{
    _baseDataSet = baseDataSet;
    
    self.closed = baseDataSet.closed;
    self.unconfirmed = baseDataSet.unconfirmed;
    self.labelIds = [baseDataSet.labelIds copy];
    self.groupIds = [baseDataSet.groupIds copy];
    self.searchText = [baseDataSet.searchText copy];
    self.searchMessageBodies = baseDataSet.searchMessageBodies;
    
    if (baseDataSet.contactClient != nil) {
        self.contactClient = baseDataSet.contactClient;
    }
}

@end
