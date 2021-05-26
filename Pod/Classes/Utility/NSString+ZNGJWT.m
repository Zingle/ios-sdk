//
//  NSString+ZNGJWT.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/22/19.
//

#import "NSString+ZNGJWT.h"

@import SBObjectiveCWrapper;

static NSString * const JwtPayloadKeyExpirationDate = @"exp";
static NSString * const JwtPayloadKeyIssueDate = @"iat";
static NSString * const JwtPayloadKeyIssuingUrl = @"iss";
static NSString * const JwtPayloadKeyStaffUser = @"staff";
static NSString * const JwtPayloadKeyHipaaUser = @"hipaa";

@implementation NSString (ZNGJWT)

- (NSDictionary<NSString *, id> * _Nullable) jwtPayload
{
    NSArray<NSString *> * jwtComponents = [self componentsSeparatedByString:@"."];
    
    // JWTs should be of the form "header.payload.signature"
    if ([jwtComponents count] != 3) {
        return nil;
    }
    
    // Objective-C's base64 decoding demands a multiple of four length, padded by `=` if needed.
    // This is idiotic and would actually violate the JWT spec.
    NSString * payload = jwtComponents[1];
    NSUInteger paddingNeeded = (4 - ([payload length] % 4)) % 4;
    NSUInteger paddedLength = [payload length] + paddingNeeded;
    NSString * paddedPayload = [payload stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    
    // The payload (jwtComponents[1]) is a base 64 encoded JSON dictionary
    NSData * data = [[NSData alloc] initWithBase64EncodedString:paddedPayload options:0];
    
    if (data == nil) {
        SBLogError(@"Unable to decode JWT payload.  Base 64 decode failed.");
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSDate * _Nullable) jwtExpiration
{
    NSNumber * expNumber = [self jwtPayload][JwtPayloadKeyExpirationDate];
    
    if ([expNumber doubleValue] == 0.0) {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[expNumber doubleValue]];
}

- (NSDate * _Nullable) jwtIssueDate
{
    NSNumber * iatNumber = [self jwtPayload][JwtPayloadKeyIssueDate];
    
    if ([iatNumber doubleValue] == 0.0) {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[iatNumber doubleValue]];
}

- (NSURL * _Nullable) jwtIssuingUrl
{
    return [NSURL URLWithString:[self jwtPayload][JwtPayloadKeyIssuingUrl]];
}

- (BOOL) isStaffUser
{
    return [[self jwtPayload][JwtPayloadKeyStaffUser] boolValue];
}

- (BOOL) isHipaaUser
{
    return [[self jwtPayload][JwtPayloadKeyHipaaUser] boolValue];
}

@end
