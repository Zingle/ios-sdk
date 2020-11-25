//
//  ZNGContactDateOrTimeInputManager.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/25/20.
//

#import "ZNGContactDateOrTimeInputManager.h"
#import "ZNGContactFieldValue.h"

@import SBObjectiveCWrapper;

@implementation ZNGContactDateOrTimeInputManager

- (id) initWithContactFieldValue: (ZNGContactFieldValue *)contactFieldValue
{
    self = [super init];
    
    if (self != nil) {
        _contactFieldValue = contactFieldValue;
    }
    
    return self;
}

+ (NSDateFormatter *) _timeFormatter24Hour
{
    static NSDateFormatter * timeFormatter24Hour;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        timeFormatter24Hour = [[NSDateFormatter alloc] init];
        timeFormatter24Hour.dateFormat = @"HH:mm";
    });
    
    return timeFormatter24Hour;
}

+ (NSDateFormatter *) _timeFormatterReadable
{
    static NSDateFormatter * timeFormatterReadable;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        timeFormatterReadable = [[NSDateFormatter alloc] init];
        timeFormatterReadable.dateStyle = NSDateFormatterNoStyle;
        timeFormatterReadable.timeStyle = NSDateFormatterShortStyle;
    });
    
    return timeFormatterReadable;
}

+ (NSDateFormatter *) _dateFormatter
{
    static NSDateFormatter * dateFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterLongStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    });
    
    return dateFormatter;
}

 + (NSDateFormatter *) _dateAndTimeFormatter
{
    static NSDateFormatter * dateAndTimeFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        dateAndTimeFormatter = [[NSDateFormatter alloc] init];
        dateAndTimeFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateAndTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    
    return dateAndTimeFormatter;
}

 + (NSDateFormatter *) _brokenServerDateFormatter
{
    static NSDateFormatter * brokenServerFormatter;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        brokenServerFormatter = [[NSDateFormatter alloc] init];
        brokenServerFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        brokenServerFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    });

    return brokenServerFormatter;
}

- (void) userSelectedDate:(NSDate *)date
{
    self.contactFieldValue.value = [self valueToSetForSelectedDate:date];
}

- (NSString *) displayValue
{
    NSDate * date = [self valueAsDate];
    
    if (date == nil) {
        // We weren't able to parse a date from this non-empty value. Let's just toss that string back
        //  and wish them luck.
        return self.contactFieldValue.value;
    }

    NSString * type = self.contactFieldValue.customField.dataType;
    NSDateFormatter * formatter;

    if ([type isEqualToString:ZNGContactFieldDataTypeTime]) {
        formatter = [[self class] _timeFormatterReadable];
    } else if ([type isEqualToString:ZNGContactFieldDataTypeDateTime]) {
        formatter = [[self class] _dateAndTimeFormatter];
    } else {
        formatter = [[self class] _dateFormatter];
    }
    
    return [formatter stringFromDate:date];
}

- (NSString *) valueToSetForSelectedDate:(NSDate *)date
{
    if (date == nil) {
        return nil;
    }
    
    NSString * type = self.contactFieldValue.customField.dataType;
    
    if (([type isEqualToString:ZNGContactFieldDataTypeDate])
        || ([type isEqualToString:ZNGContactFieldDataTypeDateTime])
        || ([type isEqualToString:ZNGContactFieldDataTypeAnniversary])) {
        
        // Return epoch seconds in string form
        return [@((NSUInteger)[date timeIntervalSince1970]) stringValue];
    }
    
    // else we are a time
    return [[[self class] _timeFormatter24Hour] stringFromDate:date];
}

// Try multiple methods of parsing the current value as a date
- (NSDate *) valueAsDate
{
    NSString * value = self.contactFieldValue.value;
    
    if ([value length] == 0) {
        return nil;
    }
    
    if ([self.contactFieldValue.customField.dataType isEqualToString:ZNGContactFieldDataTypeTime]) {
        return [[[self class] _timeFormatter24Hour] dateFromString:value];
    }
    
    NSDate * date = [[[self class] _brokenServerDateFormatter] dateFromString:value];
    
    if (date != nil) {
        SBLogWarning(@"The server is still returning incorrectly formatted timestamps.");
        return date;
    }

    long long epochNumber = [value longLongValue];
    
    if (epochNumber > 0) {
        return [NSDate dateWithTimeIntervalSince1970:epochNumber];
    }

    // I give up.
    return nil;
}

@end
