
#import "NSBundle+ZNGMessages.h"

#import "ZNGMessagesViewController.h"

@implementation NSBundle (ZNGMessages)

+ (NSString *)zng_localizedStringForKey:(NSString *)key
{
    NSBundle *bundle = [NSBundle bundleForClass:[ZNGMessagesViewController class]];
    return NSLocalizedStringFromTableInBundle(key, @"ZNGMessages", bundle, nil);
}

@end
