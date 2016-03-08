
#import "NSBundle+ZingleSDK.h"

#import "ZNGBaseViewController.h"

@implementation NSBundle (ZingleSDK)

+ (NSString *)zng_localizedStringForKey:(NSString *)key
{
    NSBundle *bundle = [NSBundle bundleForClass:[ZNGBaseViewController class]];
    return NSLocalizedStringFromTableInBundle(key, @"ZingleSDK", bundle, nil);
}

@end
