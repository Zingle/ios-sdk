//
//  ZNGConversationFlowLayout.m
//  Pods
//
//  Created by Jason Neel on 7/13/16.
//
//

#import "ZNGConversationFlowLayout.h"
#import "ZNGEvent.h"

@implementation ZNGConversationFlowLayout

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self.collectionView.dataSource collectionView:self.collectionView messageDataForItemAtIndexPath:indexPath];
    
    // If this is a message or an unknown class (not ZNGEvent,) let the default implementation handle it with bubble size witchcraft
    if ((![event isKindOfClass:[ZNGEvent class]]) || ([event isMessage])) {
        return [super sizeForItemAtIndexPath:indexPath];
    }
    
    // We have a non-message ZNGEvent
    
    // TODO: Replace this horrible temporary code
    NSString * text = [event text];
    UIFont * font = [UIFont systemFontOfSize:15.0];
    NSDictionary * attributes = @{ NSFontAttributeName : font };
    CGFloat width = [self itemWidth];
    CGSize constraintSize = CGSizeMake(width - 16.0 /* Default UILabel margins */ - 84.0 /* margin between edge of cell and UILabel */, CGFLOAT_MAX);
    CGRect rect = [text boundingRectWithSize:constraintSize
                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                  attributes:attributes
                                     context:nil];
    
    return CGSizeMake(width, rect.size.height+20.0);
}

@end
