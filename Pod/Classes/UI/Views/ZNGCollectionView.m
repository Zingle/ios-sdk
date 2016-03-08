

#import "ZNGCollectionView.h"

#import "ZNGCollectionViewFlowLayout.h"
#import "ZNGCollectionViewCellIncoming.h"
#import "ZNGCollectionViewCellOutgoing.h"

#import "ZNGTypingIndicatorFooterView.h"
#import "ZNGLoadEarlierHeaderView.h"

#import "UIColor+ZingleSDK.h"


@interface ZNGCollectionView () <ZNGLoadEarlierHeaderViewDelegate>

- (void)zng_configureCollectionView;

@end


@implementation ZNGCollectionView

@dynamic dataSource;
@dynamic delegate;
@dynamic collectionViewLayout;

#pragma mark - Initialization

- (void)zng_configureCollectionView
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.backgroundColor = [UIColor whiteColor];
    self.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    self.alwaysBounceVertical = YES;
    self.bounces = YES;
    
    [self registerNib:[ZNGCollectionViewCellIncoming nib]
          forCellWithReuseIdentifier:[ZNGCollectionViewCellIncoming cellReuseIdentifier]];
    
    [self registerNib:[ZNGCollectionViewCellOutgoing nib]
          forCellWithReuseIdentifier:[ZNGCollectionViewCellOutgoing cellReuseIdentifier]];
    
    [self registerNib:[ZNGCollectionViewCellIncoming nib]
          forCellWithReuseIdentifier:[ZNGCollectionViewCellIncoming mediaCellReuseIdentifier]];
    
    [self registerNib:[ZNGCollectionViewCellOutgoing nib]
          forCellWithReuseIdentifier:[ZNGCollectionViewCellOutgoing mediaCellReuseIdentifier]];
    
    [self registerNib:[ZNGTypingIndicatorFooterView nib]
          forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
          withReuseIdentifier:[ZNGTypingIndicatorFooterView footerReuseIdentifier]];
    
    [self registerNib:[ZNGLoadEarlierHeaderView nib]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
          withReuseIdentifier:[ZNGLoadEarlierHeaderView headerReuseIdentifier]];

    _typingIndicatorDisplaysOnLeft = YES;
    _typingIndicatorMessageBubbleColor = [UIColor zng_messageBubbleLightGrayColor];
    _typingIndicatorEllipsisColor = [_typingIndicatorMessageBubbleColor zng_colorByDarkeningColorWithValue:0.3f];

    _loadEarlierMessagesHeaderTextColor = [UIColor zng_messageBubbleGreenColor];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self zng_configureCollectionView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self zng_configureCollectionView];
}

#pragma mark - Typing indicator

- (ZNGTypingIndicatorFooterView *)dequeueTypingIndicatorFooterViewForIndexPath:(NSIndexPath *)indexPath
{
    ZNGTypingIndicatorFooterView *footerView = [super dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                 withReuseIdentifier:[ZNGTypingIndicatorFooterView footerReuseIdentifier]
                                                                                        forIndexPath:indexPath];

    [footerView configureWithEllipsisColor:self.typingIndicatorEllipsisColor
                        messageBubbleColor:self.typingIndicatorMessageBubbleColor
                       shouldDisplayOnLeft:self.typingIndicatorDisplaysOnLeft
                         forCollectionView:self];

    return footerView;
}

#pragma mark - Load earlier messages header

- (ZNGLoadEarlierHeaderView *)dequeueLoadEarlierMessagesViewHeaderForIndexPath:(NSIndexPath *)indexPath
{
    ZNGLoadEarlierHeaderView *headerView = [super dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                             withReuseIdentifier:[ZNGLoadEarlierHeaderView headerReuseIdentifier]
                                                                                    forIndexPath:indexPath];

    headerView.loadButton.tintColor = self.loadEarlierMessagesHeaderTextColor;
    headerView.delegate = self;

    return headerView;
}

#pragma mark - Load earlier messages header delegate

- (void)headerView:(ZNGLoadEarlierHeaderView *)headerView didPressLoadButton:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(collectionView:header:didTapLoadEarlierMessagesButton:)]) {
        [self.delegate collectionView:self header:headerView didTapLoadEarlierMessagesButton:sender];
    }
}

#pragma mark - Messages collection view cell delegate

- (void)messagesCollectionViewCellDidTapAvatar:(ZNGCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
            didTapAvatarImageView:cell.avatarImageView
                      atIndexPath:indexPath];
}

- (void)messagesCollectionViewCellDidTapMessageBubble:(ZNGCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self didTapMessageBubbleAtIndexPath:indexPath];
}

- (void)messagesCollectionViewCellDidTapCell:(ZNGCollectionViewCell *)cell atPosition:(CGPoint)position
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
            didTapCellAtIndexPath:indexPath
                    touchLocation:position];
}

- (void)messagesCollectionViewCell:(ZNGCollectionViewCell *)cell didPerformAction:(SEL)action withSender:(id)sender
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
                    performAction:action
               forItemAtIndexPath:indexPath
                       withSender:sender];
}

@end
