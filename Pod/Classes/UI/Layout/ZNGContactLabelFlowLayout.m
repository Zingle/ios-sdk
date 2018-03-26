//
//  ZNGContactLabelFlowLayout.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactLabelFlowLayout.h"

@import SBObjectiveCWrapper;

@implementation ZNGContactLabelFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // We will adjust our one item in the first section to be at the left margin
    NSArray<__kindof UICollectionViewLayoutAttributes *> * originalAttributes = [super layoutAttributesForElementsInRect:rect];
    BOOL foundItemInSectionZero = NO;
    
    for (UICollectionViewLayoutAttributes * attributes in originalAttributes) {
        if (attributes.indexPath.section == 0) {
            
            if (foundItemInSectionZero) {
                SBLogWarning(@"Found multiple items in section 0 of labels collection view.  Section 0 is expected to have only one item.");
            }
            
            attributes.frame = CGRectMake(self.sectionInset.left, attributes.frame.origin.y, attributes.frame.size.width, attributes.frame.size.height);
            foundItemInSectionZero = YES;
        }
    }
    
    return originalAttributes;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes * attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        attributes.frame = CGRectMake(self.sectionInset.left, attributes.frame.origin.y, attributes.frame.size.width, attributes.frame.size.height);
    }
    
    return attributes;
}

@end
