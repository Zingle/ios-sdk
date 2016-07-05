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

- (void) collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * message = [self messageAtIndexPath:indexPath];
    ZNGConversationContactToService * conversation = (ZNGConversationContactToService *)self.conversation;
    [conversation deleteMessage:message];
}

@end
