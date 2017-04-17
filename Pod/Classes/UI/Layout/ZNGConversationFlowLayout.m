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

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * eventViewModel = (ZNGEventViewModel *)[self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:indexPath];
    ZNGEvent * event = eventViewModel.event;
    
    // If this is a message/note or an unknown class (not ZNGEvent,) let the default implementation handle it with bubble size witchcraft
    if ((![event isKindOfClass:[ZNGEvent class]]) || ([event isMessage]) || ([event isNote])) {
        return [super sizeForItemAtIndexPath:indexPath];
    }
    
    // We have a non-message ZNGEvent
    NSString * text = [event text];
    UIFont * font = [UIFont systemFontOfSize:15.0];
    NSDictionary * attributes = @{ NSFontAttributeName : font };
    CGFloat width = [self itemWidth];
    CGSize constraintSize = CGSizeMake(width - 16.0 /* Default UILabel margins */ - 64.0 /* margin between edge of cell and UILabel */, CGFLOAT_MAX);
    CGRect rect = [text boundingRectWithSize:constraintSize
                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                  attributes:attributes
                                     context:nil];
    
    return CGSizeMake(width, rect.size.height+20.0);
}

@end
