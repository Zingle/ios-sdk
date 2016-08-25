//
//  ZNGContactLabelsTableViewCell.m
//  Pods
//
//  Created by Jason Neel on 8/24/16.
//
//

#import "ZNGContactLabelsTableViewCell.h"
#import "ZNGLabelRoundedCollectionViewCell.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

NSString * const ZNGContactLabelsCollectionViewCellReuseIdentifier = @"LabelCell";

@implementation ZNGContactLabelsTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    UICollectionViewFlowLayout * layout = self.collectionView.collectionViewLayout;
    layout.estimatedItemSize = CGSizeMake(110.0, 40.0);
    layout.minimumLineSpacing = 2.0;
    self.collectionView.scrollEnabled = NO;
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * nib = [UINib nibWithNibName:NSStringFromClass([ZNGLabelRoundedCollectionViewCell class]) bundle:bundle];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:ZNGContactLabelsCollectionViewCellReuseIdentifier];
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    self.collectionView.frame = CGRectMake(0, 0, targetSize.width, FLT_MAX);
    [self.collectionView layoutIfNeeded];
    
    ZNGLogVerbose(@"Labels table cell is reporting height as %.0f", self.collectionView.contentSize.height);
    
    return self.collectionView.collectionViewLayout.collectionViewContentSize;
}

@end
