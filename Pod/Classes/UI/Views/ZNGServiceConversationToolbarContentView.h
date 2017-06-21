//
//  ZNGServiceConversationToolbarContentView.h
//  Pods
//
//  Created by Jason Neel on 6/21/17.
//
//

#import "ZNGConversationToolbarContentView.h"

@interface ZNGServiceConversationToolbarContentView : ZNGConversationToolbarContentView

@property (nonatomic, strong, nullable) IBOutlet UIButton * revealButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * channelSelectButton;

- (void) collapseButtons:(BOOL)animated;
- (void) expandButtons:(BOOL)animated;

@end
