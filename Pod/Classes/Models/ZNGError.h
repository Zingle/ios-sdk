//
//  ZNGError.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import <Foundation/Foundation.h>

extern NSString * const kZingleErrorDomain;

// Additional error codes found at https://github.com/Zingle/rest-api-documentation/blob/master/error_codes.md
typedef enum {
    ZINGLE_ERROR_EMPTY_MESSAGE  =   3602
} ZingleErrorCode;

@interface ZNGError : NSError

@property(nonatomic, strong) NSString* errorText;
@property(nonatomic, strong) NSString* errorDescription;
@property(nonatomic) NSInteger httpStatusCode;
@property(nonatomic) NSInteger zingleErrorCode;

- (id)initWithAPIError:(NSError *)error;

/**
 *  Returns YES if this error represents a possible authentication failure
 */
- (BOOL) isAuthenticationFailure;

@end
