//
//  NSString+ZNGJWT.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/22/19.
//

#import <Foundation/Foundation.h>

@interface NSString (ZNGJWT)

/**
 *  The JWT's expiration date.  Nil if the string is not a JWT.
 */
- (NSDate * _Nullable) jwtExpiration;

/**
 *  The final moment this JWT can be refreshed.  Simply returns 14 days past the issue date at the moment.
 *  Returns nil if the string is not a JWT or has no issued timestamp (iat).
 */
- (NSDate * _Nullable) jwtRefreshExpiration;

/**
 *  The issue date for this JWT.  Nil if not a JWT.
 */
- (NSDate * _Nullable) jwtIssueDate;

/**
 *  The URL that issued this JWT.  Nil if not a JWT.
 */
- (NSURL * _Nullable) jwtIssuingUrl;

@end
