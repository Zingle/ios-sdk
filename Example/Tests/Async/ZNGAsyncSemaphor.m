//
//  ZNGAsyncSemaphor.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/4/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAsyncSemaphor.h"

@implementation ZNGAsyncSemaphor

@synthesize flags;

+(ZNGAsyncSemaphor *)sharedInstance
{
    static ZNGAsyncSemaphor *sharedInstance = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedInstance = [ZNGAsyncSemaphor alloc];
        sharedInstance = [sharedInstance init];
    });
    
    return sharedInstance;
}

-(id)init
{
    self = [super init];
    if (self != nil) {
        self.flags = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

-(void)dealloc
{
    self.flags = nil;
}

-(BOOL)isLifted:(NSString *)key
{
    return [self.flags objectForKey:key] != nil;
}

-(void)lift:(NSString *)key
{
    [self.flags setObject:@"YES" forKey:key];
}

-(void)waitForKey:(NSString *)key
{
    BOOL keepRunning = YES;
    while (keepRunning && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
        keepRunning = ![[ZNGAsyncSemaphor sharedInstance] isLifted:key];
    }
}

@end
