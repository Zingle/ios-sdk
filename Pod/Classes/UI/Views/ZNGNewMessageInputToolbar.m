//
//  ZNGNewMessageInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/28/16.
//
//

#import "ZNGNewMessageInputToolbar.h"

@implementation ZNGNewMessageInputToolbar

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"ZNGNewMessageToolbarContentView"
                                                                       owner:nil
                                                                     options:nil];
    return nibViews.firstObject;
}

@end
