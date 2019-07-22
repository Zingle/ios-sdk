//
//  NSString+ZNGJWT.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/22/19.
//

#import "NSString+ZNGJWT.h"

@implementation NSString (ZNGJWT)

- (NSDictionary<NSString *, id> * _Nullable) jwtPayload
{
    NSArray<NSString *> * jwtComponents = [self componentsSeparatedByString:@"."];
    
    // JWTs should be of the form "header.payload.signature"
    if ([jwtComponents count] != 3) {
        return nil;
    }
    
    // The payload (jwtComponents[1]) is a base 64 encoded JSON dictionary
    NSData * data = [[NSData alloc] initWithBase64EncodedString:jwtComponents[1] options:0];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSDate * _Nullable) jwtExpiration
{
    NSNumber * expNumber = [self jwtPayload][@"exp"];
    
    if ([expNumber doubleValue] == 0.0) {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[expNumber doubleValue]];
}

- (NSDate * _Nullable) jwtRefreshExpiration
{
    NSDictionary<NSString *, id> * payload = [self jwtPayload];
    NSTimeInterval issueTimestamp = [payload[@"iat"] doubleValue];
    
    if (issueTimestamp == 0.0) {
        return nil;
    }
    
    NSDate * issueDate = [[NSDate alloc] initWithTimeIntervalSince1970:issueTimestamp];
    
    // TODO: Pull the actual refresh expiration out of the payload if it is ever added
    NSTimeInterval fourteenDays = 14.0 * 24.0 * 60.0 * 60.0;
    return [NSDate dateWithTimeInterval:fourteenDays sinceDate:issueDate];
}

@end
