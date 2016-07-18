//
//  ZNGConversationInputToolbar.m
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import "ZNGConversationInputToolbar.h"
#import "ZNGConversationToolbarContentView.h"

@implementation ZNGConversationInputToolbar

- (JSQMessagesToolbarContentView *)loadToolbarContentView
{
    NSArray *nibViews = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([ZNGConversationToolbarContentView class])
                                                                                          owner:nil
                                                                                        options:nil];
    return nibViews.firstObject;
}

@end
