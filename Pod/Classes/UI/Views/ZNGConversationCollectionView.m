//
//  ZNGConversationCollectionView.m
//  Pods
//
//  Created by Jason Neel on 12/22/16.
//
//

#import "ZNGConversationCollectionView.h"
#import "ZNGConversationCellIncoming.h"
#import "ZNGConversationCellOutgoing.h"

@implementation ZNGConversationCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self registerNib:[ZNGConversationCellIncoming nib]
forCellWithReuseIdentifier:[ZNGConversationCellIncoming cellReuseIdentifier]];
    
    [self registerNib:[ZNGConversationCellOutgoing nib]
forCellWithReuseIdentifier:[ZNGConversationCellOutgoing cellReuseIdentifier]];
}

@end
