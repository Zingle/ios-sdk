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
@property(nonatomic) int httpStatusCode;
@property(nonatomic) int zingleErrorCode;

@end
