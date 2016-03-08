
#ifndef ZNGMessages_ZNGMessages_h
#define ZNGMessages_ZNGMessages_h

#import "ZNGMessagesViewController.h"

//  Views
#import "ZNGMessagesCollectionView.h"
#import "ZNGMessagesCollectionViewCellIncoming.h"
#import "ZNGMessagesCollectionViewCellOutgoing.h"
#import "ZNGMessagesTypingIndicatorFooterView.h"
#import "ZNGMessagesLoadEarlierHeaderView.h"

//  Layout
#import "ZNGMessagesBubbleSizeCalculating.h"
#import "ZNGMessagesBubblesSizeCalculator.h"
#import "ZNGMessagesCollectionViewFlowLayout.h"
#import "ZNGMessagesCollectionViewLayoutAttributes.h"
#import "ZNGMessagesCollectionViewFlowLayoutInvalidationContext.h"

//  Toolbar
#import "ZNGMessagesComposerTextView.h"
#import "ZNGMessagesInputToolbar.h"
#import "ZNGMessagesToolbarContentView.h"

//  Model
#import "ZNGMessageViewModel.h"

#import "ZNGMediaItem.h"
#import "ZNGPhotoMediaItem.h"
#import "ZNGLocationMediaItem.h"
#import "ZNGVideoMediaItem.h"

#import "ZNGMessagesBubbleImage.h"
#import "ZNGMessagesAvatarImage.h"

//  Protocols
#import "ZNGMessageData.h"
#import "ZNGMessageMediaData.h"
#import "ZNGMessageAvatarImageDataSource.h"
#import "ZNGMessageBubbleImageDataSource.h"
#import "ZNGMessagesCollectionViewDataSource.h"
#import "ZNGMessagesCollectionViewDelegateFlowLayout.h"

//  Factories
#import "ZNGMessagesAvatarImageFactory.h"
#import "ZNGMessagesBubbleImageFactory.h"
#import "ZNGMessagesMediaViewBubbleImageMasker.h"
#import "ZNGMessagesTimestampFormatter.h"
#import "ZNGMessagesToolbarButtonFactory.h"

//  Categories
#import "NSString+ZNGMessages.h"
#import "UIColor+ZNGMessages.h"
#import "UIImage+ZNGMessages.h"
#import "UIView+ZNGMessages.h"
#import "NSBundle+ZNGMessages.h"

#endif
