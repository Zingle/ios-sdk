//
//  ZNGInboxDataSet.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataSet.h"

@implementation ZNGInboxDataSet

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        _loading = YES;
        _contacts = @[];
        [self refresh];
    }
    
    return self;
}

- (void) refresh
{
    [self refreshStartingAtIndex:0];
}

- (void) refreshStartingAtIndex:(NSUInteger)index
{
}

@end
