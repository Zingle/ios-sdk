//
//  ZNGLogFormatter.h
//  Pods
//
//  Created by Jason Neel on 9/21/16.
//
//

#import <Foundation/Foundation.h>
@import CocoaLumberjack;

@interface ZNGLogFormatter : NSObject <DDLogFormatter>

/**
 *  Can be overridden by subclasses (i.e. to color the "ERROR" etc. string)
 */
- (NSString *) levelString:(DDLogMessage *)logMessage;

@end
