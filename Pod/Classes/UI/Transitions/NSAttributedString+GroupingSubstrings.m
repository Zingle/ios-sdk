//
//  NSAttributedString+GroupingSubstrings.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/8/18.
//

#import "NSAttributedString+GroupingSubstrings.h"

@implementation NSAttributedString (GroupingSubstrings)

- (NSArray<NSString *> * _Nullable)substringsByLineAndAttributes
{
    NSMutableArray<NSString *> * strings = [[NSMutableArray alloc] init];
    NSMutableString * currentString = [[NSMutableString alloc] init];
    NSDictionary<NSAttributedStringKey, id> * currentAttributes = nil;
    
    for (NSUInteger i = 0; i < [self length]; i++) {
        NSDictionary<NSAttributedStringKey, id> * thisCharAttributes = [self attributesAtIndex:i effectiveRange:nil];
        
        unichar thisCharacter = [self.string characterAtIndex:i];
        BOOL isNewline = [[NSCharacterSet newlineCharacterSet] characterIsMember:thisCharacter];
        BOOL sameAttributes = ((([thisCharAttributes count] == 0) && ([currentAttributes count] == 0))
                               || [thisCharAttributes isEqualToDictionary:currentAttributes]);
        BOOL groupingChangeDetected = ((isNewline) || (!sameAttributes));
        
        // Did we find something different?
        if (([currentString length] > 0) && (groupingChangeDetected)) {
            // Append the previous group
            [strings addObject:currentString];
            
            // Start the next group
            currentString = [[NSMutableString alloc] init];
            currentAttributes = thisCharAttributes;
        }
        
        // We're still building the same group
        if (!isNewline) {
            [currentString appendFormat:@"%c", thisCharacter];
        }
    }
    
    // Append the final string
    if ([currentString length] > 0) {
        [strings addObject:currentString];
    }
    
    return ([strings count] > 0) ? strings : nil;
}

@end
