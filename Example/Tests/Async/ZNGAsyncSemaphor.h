//
//  ZNGAsyncSemaphor.h
//  ZingleSDK
//
//  Created by Ryan Farley on 2/4/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZNGAsyncSemaphor : NSObject

@property (nonatomic, strong) NSMutableDictionary *flags;

+(ZNGAsyncSemaphor *)sharedInstance;

-(BOOL)isLifted:(NSString *)key;
-(void)lift:(NSString *)key;
-(void)waitForKey:(NSString *)key;

@end
