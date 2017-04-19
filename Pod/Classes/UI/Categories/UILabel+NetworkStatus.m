//
//  UILabel+NetworkStatus.m
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import "UILabel+NetworkStatus.h"

@implementation UILabel (NetworkStatus)

- (void) updateWithNetworkStatus:(ZNGNetworkLookoutStatus)status
{
    switch (status) {
        case ZNGNetworkStatusUnknown:
        case ZNGNetworkStatusConnected:
            self.text = nil;
            return;
            
        case ZNGNetworkStatusZingleSocketDisconnected:
            self.backgroundColor = [UIColor colorWithRed:0.7254902124 green:0.4784313738 blue:0.09803921729 alpha:1.0];
            self.text = @"Partially disconnected: Things may be slow. 🐢";
            return;
            
        case ZNGNetworkStatusInternetUnreachable:
            self.backgroundColor = [UIColor colorWithRed:0.521568656 green:0.1098039225 blue:0.05098039284 alpha:1.0];
            self.text = @"Disconnected: We're having trouble finding an internet connection. 🌎";
            return;
            
        case ZNGNetworkStatusZingleAPIUnreachable:
            self.backgroundColor = [UIColor colorWithRed:0.521568656 green:0.1098039225 blue:0.05098039284 alpha:1.0];
            self.text = @"Disconnected: We're having trouble connecting to Zingle. 😰";
            return;
    }
}

@end

