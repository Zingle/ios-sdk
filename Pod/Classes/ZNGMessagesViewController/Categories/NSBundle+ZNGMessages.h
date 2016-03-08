//
//  NSBundle+ZNGMessages.h
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import <Foundation/Foundation.h>

@interface NSBundle (ZNGMessages)

/**
 *  Returns a localized version of the string designated by the specified key and residing in the ZNGMessages table.
 *
 *  @param key The key for a string in the ZNGMessages table.
 *
 *  @return A localized version of the string designated by key in the ZNGMessages table.
 */
+ (NSString *)zng_localizedStringForKey:(NSString *)key;

@end
