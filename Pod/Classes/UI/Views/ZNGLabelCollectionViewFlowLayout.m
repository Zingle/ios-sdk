//
//  ZNGLabelCollectionViewFlowLayout.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGLabelCollectionViewFlowLayout.h"

@implementation ZNGLabelCollectionViewFlowLayout

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray * original   = [super layoutAttributesForElementsInRect:rect];
    NSArray * attributes = [[NSArray alloc] initWithArray:original copyItems:YES];
    
    if ([attributes count] == 1) {
        UICollectionViewLayoutAttributes *attribute = attributes.firstObject;
        CGRect frame = attribute.frame;
        frame.origin.x = 0;
        attribute.frame = frame;
        return attributes;
    }
    for(int i = 1; i < [attributes count]; ++i) {
        UICollectionViewLayoutAttributes *currentLayoutAttributes = attributes[i];
        UICollectionViewLayoutAttributes *prevLayoutAttributes = attributes[i - 1];
        NSInteger maximumSpacing = 4;

        NSInteger origin = CGRectGetMaxX(prevLayoutAttributes.frame);
        
        if(origin + maximumSpacing + currentLayoutAttributes.frame.size.width < self.collectionViewContentSize.width) {
            CGRect frame = currentLayoutAttributes.frame;
            frame.origin.x = origin + maximumSpacing;
            currentLayoutAttributes.frame = frame;
        }
    }
    return attributes;
}

@end
