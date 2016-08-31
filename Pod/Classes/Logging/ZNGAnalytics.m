//
//  ZNGAnalytics.m
//  Pods
//
//  Created by Jason Neel on 8/30/16.
//
//

#import "ZNGAnalytics.h"
#import "ZNGLogging.h"
@import Analytics;

static const int zngLogLevel = ZNGLogLevelInfo;

@implementation ZNGAnalytics

+ (instancetype) sharedAnalytics
{
    static id singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void) setSegmentWriteKey:(NSString *)segmentWriteKey
{
    if ([_segmentWriteKey length] > 0) {
        ZNGLogError(@"Segment write key being set, but it was already set earlier.  Ignoring.");
        return;
    }
    
    _segmentWriteKey = [segmentWriteKey copy];
    
    SEGAnalyticsConfiguration * config = [SEGAnalyticsConfiguration configurationWithWriteKey:_segmentWriteKey];
    config.trackApplicationLifecycleEvents = YES;
    config.recordScreenViews = YES;
    [SEGAnalytics setupWithConfiguration:config];
}

@end
