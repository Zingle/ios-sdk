//
//  NSAttributedString+GroupingSubstrings.h
//  ZingleSDK
//
//  Created by Jason Neel on 2/8/18.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (GroupingSubstrings)

/**
 *  Returns an array of substrings from this attributed string, each having consistent attributes in our attributed string
 *   and existing on a single line.
 */
- (NSArray<NSString *> * _Nullable)substringsByLineAndAttributes;

@end
