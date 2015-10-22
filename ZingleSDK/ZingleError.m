//
//  ZingleError.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import "ZingleError.h"

@implementation ZingleError

- (NSString *)description
{
    NSString *description = [super description];
    description = [description stringByAppendingFormat:@"{\r    httpStatusCode: %i\r", self.httpStatusCode];
    description = [description stringByAppendingFormat:@"    zingleErrorCode: %i\r", self.zingleErrorCode];
    description = [description stringByAppendingFormat:@"    errorText: %@\r", self.errorText];
    description = [description stringByAppendingFormat:@"    errorDescription: %@\r}", self.errorDescription];
    
    return description;
}

@end
