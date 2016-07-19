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

@implementation ZNGContactToServiceViewController

@dynamic conversation;

- (void) viewDidLoad
{
    [super viewDidLoad];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
}

- (BOOL) weAreSendingOutbound
{
    return NO;
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
