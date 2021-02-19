//
//  ZNGContactDateOrTimeInputManager.h
//  ZingleSDK
//
//  Created by Jason Neel on 11/25/20.
//

#import <Foundation/Foundation.h>

@class ZNGContactFieldValue;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides a method of tying contact field date/datetime/time values into a human readable
 *   format and user input (likely via UIDatePicker).
 */
@interface ZNGContactDateOrTimeInputManager : NSObject

- (id) initWithContactFieldValue: (ZNGContactFieldValue *)contactFieldValue;

- (void) userSelectedDate:(NSDate * _Nullable)date;
- (NSString * _Nullable) displayValue;
- (NSDate * _Nullable) valueAsDate;

@property (readonly, nonnull) ZNGContactFieldValue * contactFieldValue;

@end

NS_ASSUME_NONNULL_END
