//
//  ZNGError.h
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import <Foundation/Foundation.h>

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
