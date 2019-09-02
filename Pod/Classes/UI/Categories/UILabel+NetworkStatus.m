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
    switch (status) {
        case ZNGNetworkStatusConnectedToDevelopmentInstance:
        {
            NSBundle * bundle = [NSBundle bundleForClass:[ZingleSDK class]];
            self.backgroundColor = [UIColor colorNamed:@"ZNGBrightBackground" inBundle:bundle compatibleWithTraitCollection:nil];
            self.text = @"This is a non-production server instance. 🤡";
            return;
        }
            
        case ZNGNetworkStatusUnknown:
        case ZNGNetworkStatusConnected:
            self.text = nil;
            return;
            
        case ZNGNetworkStatusZingleSocketDisconnected:
            self.backgroundColor = [UIColor zng_errorMessageBackgroundColor];
            self.text = @"We're experiencing connection issues; things may be slow. 🐢";
            return;
            
        case ZNGNetworkStatusInternetUnreachable:
            self.backgroundColor = [UIColor zng_errorMessageBackgroundColor];
            self.text = @"We're having trouble finding an internet connection. 🌎";
            return;
            
        case ZNGNetworkStatusZingleAPIUnreachable:
            self.backgroundColor = [UIColor zng_errorMessageBackgroundColor];
            self.text = @"We're having trouble connecting to Zingle. 😰";
            return;
    }
}

@end

