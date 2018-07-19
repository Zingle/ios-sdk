//
//  ZNGEditContactHeader.m
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGEditContactHeader.h"

@implementation ZNGEditContactHeader

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.moreButton.hidden = YES;
    [self.moreButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
}

@end
