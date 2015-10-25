//
//  ZingleError.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZingleError : NSError

@property (nonatomic, retain) NSString *errorText, *errorDescription;
@property (nonatomic) int httpStatusCode, zingleErrorCode;

@end