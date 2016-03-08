
//

#import "UIDevice+ZNGMessages.h"

@implementation UIDevice (ZNGMessages)

+ (BOOL)zng_isCurrentDeviceBeforeiOS8
{
    // iOS < 8.0
    return [[UIDevice currentDevice].systemVersion compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending;
}

@end
