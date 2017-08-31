//
//  ZNGBubblesSizeCalculator.m
//  Pods
//
//  Created by Jason Neel on 10/4/16.
//
//  This is mostly a copy-paste job from JSQMessagesViewController's stock bubble sizing class because all of its data
//   is inexplicably private for JSQ reasons.  I'd rather not have to rewrite its caching logic.
//
//  All this class does differently is support NSAttributedString instead of NSString for message data.


#import "ZNGBubblesSizeCalculator.h"

#import "JSQMessagesCollectionView.h"
#import "JSQMessagesCollectionViewDataSource.h"
#import "JSQMessagesCollectionViewFlowLayout.h"
#import "JSQMessageData.h"

#import "UIImage+JSQMessages.h"

#import "ZNGEvent.h"
#import "ZNGEventViewModel.h"
#import "ZNGMessage.h"
#import "ZNGMessageData.h"

#import "ZNGLogging.h"

@interface ZNGBubblesSizeCalculator ()

@property (assign, nonatomic, readonly) NSUInteger minimumBubbleWidth;

@property (assign, nonatomic, readonly) BOOL usesFixedWidthBubbles;

@property (assign, nonatomic, readonly) NSInteger additionalInset;

@property (assign, nonatomic) CGFloat layoutWidthForFixedWidthBubbles;

@end

static const int zngLogLevel = ZNGLogLevelWarning;


@implementation ZNGBubblesSizeCalculator
{
    NSCache * cache;
}

#pragma mark - Init

- (instancetype)initWithCache:(NSCache *)theCache
           minimumBubbleWidth:(NSUInteger)minimumBubbleWidth
        usesFixedWidthBubbles:(BOOL)usesFixedWidthBubbles
{
    NSParameterAssert(theCache != nil);
    NSParameterAssert(minimumBubbleWidth > 0);
    
    self = [super init];
    if (self) {
        cache = theCache;
        _minimumBubbleWidth = minimumBubbleWidth;
        _usesFixedWidthBubbles = usesFixedWidthBubbles;
        _layoutWidthForFixedWidthBubbles = 0.0f;
        
        // this extra inset value is needed because `boundingRectWithSize:` is slightly off
        // see comment below
        _additionalInset = 3.0;
    }
    return self;
}

- (instancetype)init
{
    NSCache * aCache = [[NSCache alloc] init];
    aCache.name = @"ZNGBubblesSizeCalculator";
    aCache.countLimit = 200;
    return [self initWithCache:aCache
            minimumBubbleWidth:[UIImage jsq_bubbleCompactImage].size.width
         usesFixedWidthBubbles:NO];
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: minimumBubbleWidth=%@ usesFixedWidthBubbles=%@>",
            [self class], @(self.minimumBubbleWidth), @(self.usesFixedWidthBubbles)];
}

#pragma mark - JSQMessagesBubbleSizeCalculating

- (void)prepareForResettingLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    [cache removeAllObjects];
}

- (CGSize) messageBubbleSizeForTypingIndicator
{
    // TODO: Implement
    return CGSizeZero;
}

- (CGSize)messageBubbleSizeForMessageData:(id<JSQMessageData>)messageData
                              atIndexPath:(NSIndexPath *)indexPath
                               withLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    // Typing indicator bubbles have a consistent size
    if (([messageData conformsToProtocol:@protocol(ZNGMessageData)]) && ([(id <ZNGMessageData>)messageData isTypingIndicator])) {
        return [self messageBubbleSizeForTypingIndicator];
    }
    
    ZNGEventViewModel * viewModel = (ZNGEventViewModel *)messageData;
    NSString * cacheID = nil;
    
    if (![viewModel isKindOfClass:[ZNGEventViewModel class]]) {
        ZNGLogError(@"Non-ZNGEventViewModel object (%@) used as message data for a message bubble.  This is unexpected.", NSStringFromClass([messageData class]));
        return CGSizeZero;
    }
    
    // Only attempt to find a cached size if this message is not outgoing from us.  (i.e. do not used cached sizes for outgoing local messages)
    if (!viewModel.event.sending) {
        // Cache ID is event ID-itemIndex-flag for whether image size is exact
        cacheID = [NSString stringWithFormat:@"%@-%llu-%d", viewModel.event.eventId, (unsigned long long)viewModel.index, (int)viewModel.exactImageSizeCalculated];
        NSValue * cachedSize = [cache objectForKey:cacheID];
        
        if (cachedSize != nil) {
            ZNGLogVerbose(@"Using cached size value");
            return [cachedSize CGSizeValue];
        }
    }
    
    ZNGLogVerbose(@"No cached size value could be found.  Calculating message size.");
    
    CGSize avatarSize = [self jsq_avatarSizeForMessageData:viewModel withLayout:layout];
    
    //  from the cell xibs, there is a 2 point space between avatar and bubble
    CGFloat spacingBetweenAvatarAndBubble = 2.0f;
    CGFloat spacingBetweenAvatarAndEdgeOfCollectionView = 4.0;
    CGFloat horizontalContainerInsets = layout.messageBubbleTextViewTextContainerInsets.left + layout.messageBubbleTextViewTextContainerInsets.right;
    CGFloat horizontalFrameInsets = layout.messageBubbleTextViewFrameInsets.left + layout.messageBubbleTextViewFrameInsets.right;
    
    CGFloat horizontalInsetsTotal = horizontalContainerInsets + horizontalFrameInsets + spacingBetweenAvatarAndBubble + spacingBetweenAvatarAndEdgeOfCollectionView;
    
    CGFloat additionalHeight = self.additionalInset * 2.0;

    
    CGSize finalSize = CGSizeZero;
    
    CGSize contentSize = CGSizeZero;
    
    if ([viewModel isMediaMessage]) {
        contentSize = [viewModel mediaViewDisplaySize];
    } else {
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[viewModel text]];
        [string addAttribute:NSFontAttributeName value:layout.messageBubbleFont range:NSMakeRange(0, [string length])];
        
        CGFloat maximumTextWidth = [self textBubbleWidthForLayout:layout] - avatarSize.width - layout.messageBubbleLeftRightMargin - horizontalInsetsTotal;
        
        BOOL isIOS8OrEarlier = [[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] == NSOrderedAscending;
        NSStringDrawingOptions stringOptions = (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingUsesDeviceMetrics);
        
        if (isIOS8OrEarlier) {
            // The NSStringDrawingUsesDeviceMetrics flag causes boundingRectWithSize to glitch out and return 0x0 in iOS 8.  Remove that flag.
            // This will cause us to slightly overestimate bubble sizes in iOS 8.
            stringOptions = (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading);
        }

        // We have to add 2 to the height for Apple reasons.  Don't ask.  See similar comment below from original JSQMessages code.
        CGRect stringRect = [string boundingRectWithSize:CGSizeMake(maximumTextWidth, CGFLOAT_MAX) options:stringOptions context:nil];
        stringRect = CGRectMake(stringRect.origin.x, stringRect.origin.y, stringRect.size.width, stringRect.size.height + additionalHeight);
        contentSize = stringRect.size;
    }
    
    CGFloat verticalContainerInsets = layout.messageBubbleTextViewTextContainerInsets.top + layout.messageBubbleTextViewTextContainerInsets.bottom;
    CGFloat verticalFrameInsets = layout.messageBubbleTextViewFrameInsets.top + layout.messageBubbleTextViewFrameInsets.bottom;
    
    //  add extra 2 points of space (`self.additionalInset`), because `boundingRectWithSize:` is slightly off
    //  not sure why. magix. (shrug) if you know, submit a PR
    CGFloat verticalInsets = verticalContainerInsets + verticalFrameInsets + self.additionalInset;
    
    //  same as above, an extra 2 points of magix
    CGFloat finalWidth = MAX(contentSize.width + horizontalInsetsTotal, self.minimumBubbleWidth) + self.additionalInset;
    
    finalSize = CGSizeMake(finalWidth, contentSize.height + verticalInsets);

    if (cacheID != nil) {
        [cache setObject:[NSValue valueWithCGSize:finalSize] forKey:cacheID];
    }
    
    return finalSize;
}

- (CGSize)jsq_avatarSizeForMessageData:(id<JSQMessageData>)messageData
                            withLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    NSString *messageSender = [messageData senderId];
    
    if ([messageSender isEqualToString:[layout.collectionView.dataSource senderId]]) {
        return layout.outgoingAvatarViewSize;
    }
    
    return layout.incomingAvatarViewSize;
}

- (CGFloat)textBubbleWidthForLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    if (self.usesFixedWidthBubbles) {
        return [self widthForFixedWidthBubblesWithLayout:layout];
    }
    
    return layout.itemWidth;
}

- (CGFloat)widthForFixedWidthBubblesWithLayout:(JSQMessagesCollectionViewFlowLayout *)layout {
    if (self.layoutWidthForFixedWidthBubbles > 0.0f) {
        return self.layoutWidthForFixedWidthBubbles;
    }
    
    // also need to add `self.additionalInset` here, see comment above
    NSInteger horizontalInsets = layout.sectionInset.left + layout.sectionInset.right + self.additionalInset;
    CGFloat width = CGRectGetWidth(layout.collectionView.bounds) - horizontalInsets;
    CGFloat height = CGRectGetHeight(layout.collectionView.bounds) - horizontalInsets;
    self.layoutWidthForFixedWidthBubbles = MIN(width, height);
    
    return self.layoutWidthForFixedWidthBubbles;
}

@end
