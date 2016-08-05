//
//  UIFont+Lato.m
//  Zingle
//
//  Created by Jason Neel on 8/4/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "UIFont+Lato.h"

@implementation UIFont (Lato)

+ (UIFont *) latoFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Regular" size:size];
}

+ (UIFont  *) latoSemiBoldFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Semibold" size:size];
}

+ (UIFont *) latoBoldFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Lato-Bold" size:size];
}

@end
