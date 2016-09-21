//
//  ZNGColoredLogFormatter.m
//  Pods
//
//  Created by Jason Neel on 9/21/16.
//
//

#import "ZNGColoredLogFormatter.h"

#define XCODE_COLORS_ESCAPE @"\033["

@implementation ZNGColoredLogFormatter

- (NSString *)levelString:(DDLogMessage *)logMessage
{
    if (logMessage.flag & DDLogFlagVerbose) {
        return @"VERBOSE";
    } else if (logMessage.flag & DDLogFlagDebug) {
        return @" DEBUG ";
    } else if (logMessage.flag & DDLogFlagInfo) {
        return [NSString stringWithFormat:@"%@fg255,255,255;%@bg3,80,0; INFO  %@;", XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE];
    } else if (logMessage.flag & DDLogFlagWarning) {
        return [NSString stringWithFormat:@"%@fg0,0,0;%@bg241,232,6;WARNING%@;", XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE];
    } else if (logMessage.flag & DDLogFlagError) {
        return [NSString stringWithFormat:@"%@fg255,255,255;%@bg154,0,0; ERROR %@;", XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE, XCODE_COLORS_ESCAPE];
    }
    
    return [super levelString:logMessage];
} 

@end
