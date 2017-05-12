//
//  ZNGLabel.m
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import "ZNGLabel.h"
#import "ZNGLogging.h"
#import "UIColor+ZingleSDK.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGLabel

- (BOOL) isEqual:(ZNGLabel *)other
{
    if (![other isKindOfClass:[ZNGLabel class]]) {
        return NO;
    }
    
    return ([self.labelId isEqual:other.labelId]);
}

- (NSUInteger) hash
{
    return [self.labelId hash];
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             @"labelId" : @"id",
             @"displayName" : @"display_name",
             @"backgroundColor" : @"background_color",
             @"textColor" : @"text_color",
             @"isGlobal" : @"is_global"
             };
}

- (UIColor *)textUIColor
{
    NSString * colorString = self.textColor;
    
    if ([colorString length] == 0) {
        ZNGLogInfo(@"%@ label has no text color information.  Using default #ffffff", self.displayName);
        colorString = @"#ffffff";
    }
    
    return [UIColor colorFromHexString:colorString];
}

- (UIColor *)backgroundUIColor
{
    NSString * colorString = self.backgroundColor;
    
    if ([colorString length] == 0) {
        ZNGLogInfo(@"%@ label has no text color information.  Using default #595959", self.displayName);
        colorString = @"#595959";
    }
    
    return [UIColor colorFromHexString:colorString];
}

- (BOOL) matchesSearchTerm:(NSString *)term
{
    NSString * lowerTerm = [term lowercaseString];
    return ([[self.displayName lowercaseString] containsString:lowerTerm]);
}

@end
