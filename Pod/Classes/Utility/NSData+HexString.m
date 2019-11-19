//
//  NSData+HexString.m
//  ZingleSDK
//
//  Created by Jason Neel on 11/19/19.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)

- (NSString *) hexString
{
    if ([self length] == 0) {
        return nil;
    }
    
    const uint8_t * bytes = [self bytes];
    NSUInteger length = [self length];
    NSMutableString * stringy = [[NSMutableString alloc] initWithCapacity:(length * 2)];
    for (NSUInteger i=0; i < length; i++) {
        [stringy appendString:[NSString stringWithFormat:@"%02.2hhx", bytes[i]]];
    }
    
    return stringy;
}

@end
