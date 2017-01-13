//
//  ZNGEventViewModel.m
//  Pods
//
//  Created by Jason Neel on 1/13/17.
//

#import "ZNGEventViewModel.h"
#import "ZNGEvent.h"

@implementation ZNGEventViewModel

- (id) initWithEvent:(ZNGEvent *)event index:(NSUInteger)index
{
    self = [super init];
    
    if (self != nil) {
        _event = event;
        _index = index;
    }
    
    return self;
}

- (NSUInteger) hash
{
    return [[self.event.eventId stringByAppendingFormat:@"%llu", (unsigned long long)self.index] hash];
}

- (BOOL) isEqual:(ZNGEventViewModel *)object
{
    if (![object isKindOfClass:[ZNGEventViewModel class]]) {
        return NO;
    }
    
    return ((self.index == object.index) && ([self.event.eventId isEqualToString:object.event.eventId]));
}

@end
