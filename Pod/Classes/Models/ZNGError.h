//
//  ZNGError.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kZingleErrorDomain;

// Additional error codes found at https://github.com/Zingle/rest-api-documentation/blob/master/error_codes.md
typedef enum {
    ZINGLE_ERROR_CHANNEL_MISSING_COUNTRY    =   3103,
    ZINGLE_ERROR_EMPTY_MESSAGE  =   3602
} ZingleErrorCode;

@interface ZNGError : NSError

@property(nonatomic, strong, nullable) NSString* errorText;
@property(nonatomic, strong, nullable) NSString* errorDescription;
@property(nonatomic) NSInteger httpStatusCode;
@property(nonatomic) NSInteger zingleErrorCode;

/**
 *  Initialize from an NSError
 */
- (id)initWithAPIError:(NSError *)error;

/**
 *  Initialize from an NSError, optionally using an NSURLResponse to find an HTTP error code if no
 *   code is available in the NSError but the response is an NSHTTPURLResponse.
 */
- (id)initWithAPIError:(NSError *)error response:(NSURLResponse * _Nullable)response;

/**
 *  Returns YES if this error represents a possible authentication failure
 */
- (BOOL) isAuthenticationFailure;

/**
 *  Returns YES if this error indicates that the user's email needs to be verified
 */
- (BOOL) isUnverifiedEmailError;

@end

NS_ASSUME_NONNULL_END
