//
//  ZNGContactLabelFlowLayout.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactLabelFlowLayout.h"

@implementation ZNGContactLabelFlowLayout

//- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
//{
//    NSArray<__kindof UICollectionViewLayoutAttributes *> * originalAttributes = [super layoutAttributesForElementsInRect:rect];
//    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> * newAttributes = [[NSMutableArray alloc] initWithCapacity:[originalAttributes count]];
//    CGFloat leftMargin = self.sectionInset.left;
//    
//    for (UICollectionViewLayoutAttributes * attributes in originalAttributes) {
//        BOOL foundRowSibling = NO;
//        
//        for (UICollectionViewLayoutAttributes * otherAttributes in originalAttributes) {
//            if (attributes == otherAttributes) {
//                continue;
//            }
//            
//            if (attributes.frame.origin.y == otherAttributes.frame.origin.y) {
//                foundRowSibling = YES;
//                break;
//            }
//        }
//        
//        if (!foundRowSibling) {
//            // Get leftward, dude
//            attributes.frame = CGRectOffset(attributes.frame, -(attributes.frame.origin.x - leftMargin), 0.0);
//        }
//        
//        [newAttributes addObject:attributes];
//    }
//    
//    return newAttributes;
//}

//- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
//    NSArray * original   = [super layoutAttributesForElementsInRect:rect];
//    NSArray * attributes = [[NSArray alloc] initWithArray:original copyItems:YES];
//    
//    if ([attributes count] == 1) {
//        UICollectionViewLayoutAttributes *attribute = attributes.firstObject;
//        CGRect frame = attribute.frame;
//        frame.origin.x = 0;
//        attribute.frame = frame;
//        return attributes;
//    }
//    for(int i = 1; i < [attributes count]; ++i) {
//        UICollectionViewLayoutAttributes *currentLayoutAttributes = attributes[i];
//        UICollectionViewLayoutAttributes *prevLayoutAttributes = attributes[i - 1];
//        NSInteger maximumSpacing = 4;
//        
//        NSInteger origin = CGRectGetMaxX(prevLayoutAttributes.frame);
//        
//        if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < self.collectionViewContentSize.width) {
//            CGRect frame = currentLayoutAttributes.frame;
//            frame.origin.x = origin + maximumSpacing;
//            currentLayoutAttributes.frame = frame;
//        }
//    }
//    return attributes;
//}

@end
