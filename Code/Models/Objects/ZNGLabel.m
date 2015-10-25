//
//  ZNGLabel.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGLabel.h"
#import "ZingleModel.h"
#import "NSMutableDictionary+json.h"
#import "ZingleDAO.h"
#import "ZNGService.h"
#import "ZingleSDK.h"

NSString * const ZINGLE_COLOR_DARK_GRAY        = @"#595959";
NSString * const ZINGLE_COLOR_GRAY             = @"#c6c6c6";
NSString * const ZINGLE_COLOR_LIGHT_GRAY       = @"#e2e2e2";
NSString * const ZINGLE_COLOR_GREEN            = @"#00e97d";
NSString * const ZINGLE_COLOR_BROWN            = @"#875860";
NSString * const ZINGLE_COLOR_RED              = @"#dc4429";
NSString * const ZINGLE_COLOR_EXTRA_DARK_BLUE  = @"#155e8c";
NSString * const ZINGLE_COLOR_DARK_BLUE        = @"#0992d2";
NSString * const ZINGLE_COLOR_BLUE             = @"#00a1df";
NSString * const ZINGLE_COLOR_LIGHT_BLUE       = @"#26afe4";
NSString * const ZINGLE_COLOR_EXTRA_LIGHT_BLUE = @"#e5f5fc";

#define UIColorFromHex(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:1.0]

@interface ZNGLabel()

- (unsigned int)intFromHexString:(NSString *)hexStr;
@property (nonatomic, retain) NSString *backgroundColorHex, *textColorHex;

@end

@implementation ZNGLabel

- (id)initWithService:(ZNGService *)service
{
    if( self = [super init] )
    {
        self.service = service;
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"services/%@/contact-labels/%@", self.service.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"services/%@/contact-labels", self.service.ID];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.backgroundColorHex = [data objectAtPath:@"background_color" expectedClass:[NSString class] default:@""];
    self.textColorHex = [data objectAtPath:@"text_color" expectedClass:[NSString class] default:@""];
    
    self.isGlobal = [[data objectAtPath:@"is_global" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
}

- (NSError *)preSaveValidation
{
    if( self.service == nil ) {
        return [[ZingleSDK sharedSDK] genericError:@"Label must be linked to a Service." code:0];
    }
    if( self.displayName == nil || [self.displayName isEqualToString:@""] ) {
        return [[ZingleSDK sharedSDK] genericError:@"Label display name cannot be empty." code:0];
    }
    return nil;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.displayName forKey:@"display_name"];
    [dictionary setObject:self.backgroundColorHex forKey:@"background_color"];
    [dictionary setObject:self.textColorHex forKey:@"text_color"];
    
    return dictionary;
}

- (NSString *)description
{
    NSString *description = @"<ZNGLabel> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    backgroundColorHex: %@\r", self.backgroundColorHex];
    description = [description stringByAppendingFormat:@"    textColorHex: %@\r", self.textColorHex];
    description = [description stringByAppendingFormat:@"    isGlobal: %d\r", self.isGlobal];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

- (void)setDefaultColors
{
    self.backgroundColorHex = @"#595959";
    self.textColorHex       = @"#ffffff";
}

- (void)setBackgroundColorHex:(NSString *)backgroundColorHex
{
    _backgroundColorHex = [self standardizeHEX:backgroundColorHex default:@"#595959"];
    _backgroundColor = UIColorFromHex([self intFromHexString:_backgroundColorHex]);
}

- (void)setTextColorHex:(NSString *)textColorHex
{
    _textColorHex = [self standardizeHEX:textColorHex default:@"#ffffff"];
    _textColor = UIColorFromHex([self intFromHexString:_textColorHex]);
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    _backgroundColorHex = [ZNGLabel hexFromUIColor:backgroundColor];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _textColorHex = [ZNGLabel hexFromUIColor:textColor];
}

- (unsigned int)intFromHexString:(NSString *)hexStr
{
    unsigned int hexInt = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexInt];
    return hexInt;
}

+ (NSString *)hexFromUIColor:(UIColor *)color
{
    CGFloat rf, gf, bf, af;
    [color getRed:&rf green:&gf blue: &bf alpha: &af];
    
    int ri = (int)(255.0 * rf);
    int gi = (int)(255.0 * gf);
    int bi = (int)(255.0 * bf);
    
    return [NSString stringWithFormat:@"#%02x%02x%02x", ri, gi, bi];
}

- (NSString *)standardizeHEX:(NSString *)hexColor default:(NSString *)defaultHex
{
    if( ![ZNGLabel isValidHEXColor:hexColor] )
    {
        hexColor = defaultHex;
    }
    
    if( [hexColor length] == 6 )
    {
        hexColor = [NSString stringWithFormat:@"#%@", hexColor];
    }
    
    return [hexColor lowercaseString];
}

+ (BOOL)isValidHEXColor:(NSString *)hexColor
{
    NSPredicate *hexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^#?[0-9a-fA-F]{6}$"];
    return [hexPredicate evaluateWithObject:hexColor];
}

@end
