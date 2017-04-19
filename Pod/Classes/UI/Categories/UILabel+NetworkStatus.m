//
//  UILabel+NetworkStatus.m
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import "UILabel+NetworkStatus.h"
#import "UIColor+ZingleSDK.h"

@implementation UILabel (NetworkStatus)

- (void) updateWithNetworkStatus:(ZNGNetworkLookoutStatus)status
{
    switch (status) {
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

