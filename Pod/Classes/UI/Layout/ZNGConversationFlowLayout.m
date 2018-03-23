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
#import "ZNGMessageData.h"

@import SBObjectiveCWrapper;

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
            SBLogVerbose(@"%s: Setting %@ frame for %@ view", __PRETTY_FUNCTION__, NSStringFromCGRect(attributes.frame), attributes.representedElementKind);
            attributes.zIndex = 10;
        }
    }];
    
    return allAttributes;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <ZNGMessageData> messageData = (id <ZNGMessageData>)[self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:indexPath];
    
    // If this is an event but not a message nor a note, we have custom logic
    if ([messageData isKindOfClass:[ZNGEventViewModel class]]) {
        ZNGEventViewModel * viewModel = (ZNGEventViewModel *)messageData;
        ZNGEvent * event = viewModel.event;
        
        if ((![event isMessage]) && (![event isNote])) {
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
    }
    
    // Default implementation for a message, note, or typing indicator
    return [super sizeForItemAtIndexPath:indexPath];
}

@end
