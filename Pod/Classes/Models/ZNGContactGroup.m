//
//  ZNGContactGroup.m
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import "ZNGContactGroup.h"
#import "ZNGCondition.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGContactGroup

+ (NSDictionary*) JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(groupId)): @"id",
             NSStringFromSelector(@selector(displayName)): @"display_name",
             NSStringFromSelector(@selector(conditionBooleanOperator)): @"condition_boolean_operator",
             NSStringFromSelector(@selector(conditions)): @"conditions",
             NSStringFromSelector(@selector(textColor)): @"text_color",
             NSStringFromSelector(@selector(backgroundColor)): @"background_color"
             };
}

+ (NSValueTransformer *) conditionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ZNGCondition class]];
}

- (BOOL) matchesSearchTerm:(NSString *)term
{
    NSString * lowerTerm = [term lowercaseString];
    return ([[self.displayName lowercaseString] containsString:lowerTerm]);
}

+ (MTLValueTransformer *) reversibleColorFromJSONStringTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString * colorString) {
        return [UIColor colorFromHexString:colorString];
    } reverseBlock:^id(UIColor * color) {
        if (color == nil) {
            return nil;
        }
        
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        
        CGFloat r = components[0];
        CGFloat g = components[1];
        CGFloat b = components[2];
        
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255)];
    }];
}

+ (NSValueTransformer *) textColorJSONTransformer
{
    return [self reversibleColorFromJSONStringTransformer];
}

+ (NSValueTransformer *) backgroundColorJSONTransformer
{
    return [self reversibleColorFromJSONStringTransformer];
}

- (UIColor *)textColor
{
    if (_textColor == nil) {
        return [UIColor whiteColor];
    }
    
    return _textColor;
}

- (UIColor *)backgroundColor
{
    if (_backgroundColor == nil) {
        // Match the magic default value the server sometimes sends when it decides not to just send null like other times.
        return [UIColor colorFromHexString:@"#595959"];
    }
    
    return _backgroundColor;
}

@end
