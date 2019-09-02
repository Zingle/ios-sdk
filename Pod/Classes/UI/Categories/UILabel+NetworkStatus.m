//
//  UILabel+NetworkStatus.m
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import "ZingleSDK.h"
#import "UILabel+NetworkStatus.h"
#import "UIColor+ZingleSDK.h"

@implementation UILabel (NetworkStatus)

- (void) updateWithNetworkStatus:(ZNGNetworkLookoutStatus)status
{
    NSBundle * bundle = [NSBundle bundleForClass:[ZingleSDK class]];
    UIColor * errorBackgroundColor = [UIColor colorNamed:@"ZNGDarkBannerBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    
    switch (status) {
        case ZNGNetworkStatusConnectedToDevelopmentInstance:
            self.backgroundColor = [UIColor colorNamed:@"ZNGBrightBackground" inBundle:bundle compatibleWithTraitCollection:nil];
            self.text = @"This is a non-production server instance. 🤡";
            return;
            
        case ZNGNetworkStatusUnknown:
        case ZNGNetworkStatusConnected:
            self.text = nil;
            return;
            
        case ZNGNetworkStatusZingleSocketDisconnected:
            self.backgroundColor = errorBackgroundColor;
            self.text = @"We're experiencing connection issues; things may be slow. 🐢";
            return;
            
        case ZNGNetworkStatusInternetUnreachable:
            self.backgroundColor = errorBackgroundColor;
            self.text = @"We're having trouble finding an internet connection. 🌎";
            return;
            
        case ZNGNetworkStatusZingleAPIUnreachable:
            self.backgroundColor = errorBackgroundColor;
            self.text = @"We're having trouble connecting to Zingle. 😰";
            return;
    }
}

@end

