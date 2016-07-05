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

@implementation ZNGContactToServiceViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender;
{
    if (action == @selector(delete:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    ZNGMessage * message = [self messageAtIndexPath:indexPath];
    ZNGConversationContactToService * conversation = (ZNGConversationContactToService *)self.conversation;
    [conversation deleteMessage:message];
}

@end
