//
//  ZNGContactToServiceViewController.m
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import "ZNGContactToServiceViewController.h"
#import <JSQMessagesViewController/JSQMessagesCollectionViewCell.h>
#import "ZNGConversationContactToService.h"
#import "ZNGEvent.h"
#import "UIColor+ZingleSDK.h"

@implementation ZNGContactToServiceViewController

@dynamic conversation;

- (void) viewDidLoad
{
    [super viewDidLoad];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UIImage * photoImage = [UIImage imageNamed:@"attachImage" inBundle:bundle compatibleWithTraitCollection:nil];
    UIButton * photoButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 24.0)];
    photoButton.tintColor = [UIColor zng_gray];
    [photoButton setImage:photoImage forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(pressedAttachImage:) forControlEvents:UIControlEventTouchUpInside];
    self.inputToolbar.contentView.leftBarButtonItem = photoButton;
    
    UIButton * sendButton = self.inputToolbar.contentView.rightBarButtonItem;
    [sendButton setTitleColor:[UIColor zng_green] forState:UIControlStateNormal];
    [sendButton setTitleColor:[[UIColor zng_green] zng_colorByDarkeningColorWithValue:0.1f] forState:UIControlStateHighlighted];
    sendButton.tintColor = [UIColor zng_green];
}

- (BOOL) weAreSendingOutbound
{
    return NO;
}

- (void) pressedAttachImage:(id)sender
{
    [self inputToolbar:self.inputToolbar didPressAttachImageButton:sender];
}

#pragma mark - Details button
- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton
{
    NSArray<UIAlertAction *> * superActions = [super alertActionsForDetailsButton];
    NSMutableArray<UIAlertAction *> * actions = ([superActions count] > 0) ? [superActions mutableCopy] : [[NSMutableArray alloc] init];
    
    UIAlertAction * deleteAllMessages = [UIAlertAction actionWithTitle:@"Delete all messages" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        ZNGConversationContactToService * conversation = (ZNGConversationContactToService *)self.conversation;
        [conversation deleteAllMessages];
    }];
    
    [actions addObject:deleteAllMessages];
    
    return actions;
}

#pragma mark - Collection view menu actions
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
{
    if (action == @selector(delete:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    ZNGConversationContactToService * conversation = (ZNGConversationContactToService *)self.conversation;
    
    if (event.message != nil) {
        [conversation deleteMessage:event.message];
    }
}

@end
