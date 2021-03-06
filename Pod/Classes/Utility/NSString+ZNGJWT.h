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
 *  The issue date for this JWT.  Nil if not a JWT.
 */
- (NSDate * _Nullable) jwtIssueDate;

/**
 *  The URL that issued this JWT.  Nil if not a JWT.
 */
- (NSURL * _Nullable) jwtIssuingUrl;

/**
 *  Is the current user a staff user?
 */
- (BOOL) isStaffUser;

/**
 *  Is the current user a HIPAA user?
 */
- (BOOL) isHipaaUser;

@end
