//
//  ZNGLogFormatter.m
//  Pods
//
//  Created by Jason Neel on 9/21/16.
//
//

#import "ZNGLogFormatter.h"

@implementation ZNGLogFormatter
{
    NSDateFormatter * dateFormatter;
}

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss";
    }
    
    return self;
}

- (NSString *) formatLogMessage:(DDLogMessage *)logMessage
{
    NSString * levelString = [self levelString:logMessage];
    NSString * timestamp = [dateFormatter stringFromDate:logMessage.timestamp];
    
    NSString * string = [NSString stringWithFormat:@"%@ %@ %@:%lld: %@", timestamp, levelString, logMessage.fileName, (unsigned long long)logMessage.line, logMessage.message];
    return string;
}

- (NSString *) levelString:(DDLogMessage *)logMessage
{
    if (logMessage.level & DDLogFlagError) {
        return @"ERROR";
    } else if (logMessage.level & DDLogFlagWarning) {
        return @"WARNING";
    } else if (logMessage.level & DDLogFlagInfo) {
        return @"INFO";
    } else if (logMessage.level & DDLogFlagDebug) {
        return @"DEBUG";
    }
    
    return @"VERBOSE";
}


@end
