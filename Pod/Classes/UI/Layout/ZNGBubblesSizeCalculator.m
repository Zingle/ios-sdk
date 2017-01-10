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
#import "ZNGMessage.h"

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

}

- (CGSize)messageBubbleSizeForMessageData:(id<JSQMessageData>)messageData
                              atIndexPath:(NSIndexPath *)indexPath
                               withLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    ZNGEvent * event = (ZNGEvent *)messageData;
    
    if (![event isKindOfClass:[ZNGEvent class]]) {
        ZNGLogError(@"Non-ZNGEvent object used as message data for a message bubble.  This is unexpected.");
        return CGSizeZero;
    }
    
    NSString * idIncludingImageCount;
    
    if ([event.message.attachments count] == 0) {
        idIncludingImageCount = event.eventId;
    } else {
        // We have one or more attachments
        idIncludingImageCount = [NSString stringWithFormat:@"%@-%llu", event.eventId, (unsigned long long)[event.message.imageAttachmentsByName count]];
    }
    
    NSValue * cachedSize = [cache objectForKey:idIncludingImageCount];
    
    if (cachedSize != nil) {
        ZNGLogVerbose(@"Using cached size value");
        return [cachedSize CGSizeValue];
    }
    
    ZNGLogVerbose(@"No cached size value could be found.  Calculating message size.");
    
    CGSize finalSize = CGSizeZero;
    
    CGSize avatarSize = [self jsq_avatarSizeForMessageData:messageData withLayout:layout];
    
    //  from the cell xibs, there is a 2 point space between avatar and bubble
    CGFloat spacingBetweenAvatarAndBubble = 2.0f;
    CGFloat spacingBetweenAvatarAndEdgeOfCollectionView = 4.0;
    CGFloat horizontalContainerInsets = layout.messageBubbleTextViewTextContainerInsets.left + layout.messageBubbleTextViewTextContainerInsets.right;
    CGFloat horizontalFrameInsets = layout.messageBubbleTextViewFrameInsets.left + layout.messageBubbleTextViewFrameInsets.right;
    
    CGFloat horizontalInsetsTotal = horizontalContainerInsets + horizontalFrameInsets + spacingBetweenAvatarAndBubble + spacingBetweenAvatarAndEdgeOfCollectionView;
    CGFloat maximumTextWidth = [self textBubbleWidthForLayout:layout] - avatarSize.width - layout.messageBubbleLeftRightMargin - horizontalInsetsTotal;
    
    CGRect stringRect;
    
    NSUInteger loadedImagesCount = 0;
    
    loadedImagesCount = [event.message.imageAttachmentsByName count];
    NSMutableAttributedString * string = [[event attributedText] mutableCopy];
    [string addAttribute:NSFontAttributeName value:layout.messageBubbleFont range:NSMakeRange(0, [string length])];
    
    CGFloat additionalHeight = ((loadedImagesCount + 1.0) * self.additionalInset * 2.0);

    // We have to add 2 to the height for Apple reasons.  Don't ask.  See similar comment below from original JSQMessages code.
    stringRect = [string boundingRectWithSize:CGSizeMake(maximumTextWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingUsesDeviceMetrics) context:nil];
    stringRect = CGRectMake(stringRect.origin.x, stringRect.origin.y, stringRect.size.width, stringRect.size.height + additionalHeight);
    
    CGSize stringSize = CGRectIntegral(stringRect).size;
    
    CGFloat verticalContainerInsets = layout.messageBubbleTextViewTextContainerInsets.top + layout.messageBubbleTextViewTextContainerInsets.bottom;
    CGFloat verticalFrameInsets = layout.messageBubbleTextViewFrameInsets.top + layout.messageBubbleTextViewFrameInsets.bottom;
    
    //  add extra 2 points of space (`self.additionalInset`), because `boundingRectWithSize:` is slightly off
    //  not sure why. magix. (shrug) if you know, submit a PR
    CGFloat verticalInsets = verticalContainerInsets + verticalFrameInsets + self.additionalInset;
    
    //  same as above, an extra 2 points of magix
    CGFloat finalWidth = MAX(stringSize.width + horizontalInsetsTotal, self.minimumBubbleWidth) + self.additionalInset;
    
    finalSize = CGSizeMake(finalWidth, stringSize.height + verticalInsets);

    [cache setObject:[NSValue valueWithCGSize:finalSize] forKey:idIncludingImageCount];
    
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
