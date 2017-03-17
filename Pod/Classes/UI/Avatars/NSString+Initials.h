//
//  NSString+Initials.h
//  Pods
//
//  Created by Jason Neel on 3/17/17.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Initials)

/**
 *  Returns initials of the form "JCN", treating the string as a name.
 */
- (NSString *)initials;

@end
