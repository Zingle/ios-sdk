//
//  NSAttributedString+Mentions.m
//  ZingleSDK
//
//  Created by Serhii Derhach on 27.04.2021.
//

#import "NSAttributedString+Mentions.h"
#import "ZNGEventViewModel.h"

@implementation NSAttributedString (Mentions)

- (NSString *)formattedMentionForAPI
{
    NSMutableString * formattedNote = self.string.mutableCopy;
    [self enumerateAttributesInRange:NSMakeRange(0, formattedNote.length)
                             options:NSAttributedStringEnumerationReverse
                          usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop)
    {
        if ([attributes.allKeys containsObject:ZNGEventMentionAttribute]) {
            NSString * replacementString;
            NSString * userUuid = attributes[ZNGEventUserMentionAttribute];
            if (userUuid.length) {
                replacementString = [NSString stringWithFormat:@"{u@%@}", userUuid];
            } else {
                NSString * teamUuid = attributes[ZNGEventTeamMentionAttribute];
                if (teamUuid.length) {
                    replacementString = [NSString stringWithFormat:@"{t@%@}", teamUuid];
                }
            }
            if (replacementString.length) {
                [formattedNote replaceCharactersInRange:range withString:replacementString];
            }
        }
    }];
    return formattedNote;
}

- (NSString *)mentionedContactType
{
    __block NSString * mentionedContactType = @"";
    [self enumerateAttributesInRange:NSMakeRange(0, self.length)
                             options:NSAttributedStringEnumerationReverse
                          usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop)
     {
        NSArray * allKeys = attributes.allKeys;
        if ([allKeys containsObject:ZNGEventTeamMentionAttribute]) {
            mentionedContactType = @"team";
        }
        else if ([allKeys containsObject:ZNGEventUserMentionAttribute]) {
            mentionedContactType = @"user";
        }
    }];
    return mentionedContactType;
}

@end
