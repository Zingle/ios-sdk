//
//  NSAttributedString+Mentions.h
//  ZingleSDK
//
//  Created by Serhii Derhach on 27.04.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (Mentions)

/**
 *  Returns plain string having replaced 'Mention' attributes with API-ready '{}'-format
 */
- (NSString *)formattedMentionForAPI;

@end

NS_ASSUME_NONNULL_END
