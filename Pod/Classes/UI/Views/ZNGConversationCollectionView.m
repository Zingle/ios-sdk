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
    
    // Something is changing the collection view background color from its storyboard setting of systemBackgroundColor
    //  to the old default of white.  Stop that!
    if (@available(iOS 13.0, *)) {
        self.backgroundColor = [UIColor systemBackgroundColor];
    }
    
    [self registerNib:[ZNGConversationCellIncoming nib]
forCellWithReuseIdentifier:[ZNGConversationCellIncoming cellReuseIdentifier]];
    
    [self registerNib:[ZNGConversationCellOutgoing nib]
forCellWithReuseIdentifier:[ZNGConversationCellOutgoing cellReuseIdentifier]];
    
    [self registerNib:[ZNGConversationCellIncoming nib] forCellWithReuseIdentifier:[ZNGConversationCellIncoming mediaCellReuseIdentifier]];
    
    [self registerNib:[ZNGConversationCellOutgoing nib] forCellWithReuseIdentifier:[ZNGConversationCellOutgoing mediaCellReuseIdentifier]];
}

@end
