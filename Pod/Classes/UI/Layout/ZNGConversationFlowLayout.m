//
//  ZNGConversationFlowLayout.m
//  Pods
//
//  Created by Jason Neel on 7/13/16.
//
//

#import "ZNGConversationFlowLayout.h"
#import "ZNGEvent.h"
#import "ZNGEventViewModel.h"
#import "ZNGBubblesSizeCalculator.h"
#import "UIFont+Lato.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

@interface JSQMessagesCollectionViewFlowLayout ()
- (void)jsq_configureFlowLayout;
@end

@implementation ZNGConversationFlowLayout

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    self.bubbleSizeCalculator = [[ZNGBubblesSizeCalculator alloc] init];
}

- (void) jsq_configureFlowLayout
{
    [super jsq_configureFlowLayout];
    
    self.messageBubbleTextViewTextContainerInsets = UIEdgeInsetsMake(10.0, 15.0, 10.0, 8.0);
    self.messageBubbleLeftRightMargin = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 50.0 : 25.0;
    self.minimumLineSpacing = 6.0;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // Stop JSQMessagesCollectionViewFlowLayout from setting our header z index to -1 and causing an assertion failure
    NSArray<UICollectionViewLayoutAttributes *> * allAttributes = [[super layoutAttributesForElementsInRect:rect] copy];
    
    [allAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull attributes, NSUInteger idx, BOOL * _Nonnull stop) {
        if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView) {
            ZNGLogVerbose(@"%s: Setting %@ frame for %@ view", __PRETTY_FUNCTION__, NSStringFromCGRect(attributes.frame), attributes.representedElementKind);
            attributes.zIndex = 10;
        }
    }];
    
    return allAttributes;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * eventViewModel = (ZNGEventViewModel *)[self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:indexPath];
    ZNGEvent * event = eventViewModel.event;
    
    if (![eventViewModel isKindOfClass:[ZNGEventViewModel class]]) {
        ZNGLogError(@"Unexpected %@ in data source.  You are not an event view model >:(", [eventViewModel class]);
        return [super sizeForItemAtIndexPath:indexPath];
    }
    
    // If this is a message/note, let the default implementation handle it with bubble size witchcraft
    if (([event isMessage]) || ([event isNote])) {
        return [super sizeForItemAtIndexPath:indexPath];
    }
    
    // We have a non-message ZNGEvent
    NSString * text = [event text];
    UIFont * font = [UIFont latoBoldFontOfSize:13.0];
    NSDictionary * attributes = @{ NSFontAttributeName : font };
    CGFloat width = [self itemWidth];
    CGFloat marginWithinCell = 22.0 + 32.0 + 20.0;
    CGSize constraintSize = CGSizeMake(width - (marginWithinCell * 2.0), CGFLOAT_MAX);
    CGRect rect = [text boundingRectWithSize:constraintSize
                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                  attributes:attributes
                                     context:nil];
    
    return CGSizeMake(width, rect.size.height+20.0);
}

@end
