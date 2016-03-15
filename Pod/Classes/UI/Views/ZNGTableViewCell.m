//
//  ZNGTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGTableViewCell.h"
#import "ZNGTimestampFormatter.h"
#import "ZNGLabel.h"
#import "ZNGLabelCollectionViewCell.h"
#import "ZNGLabelCollectionViewFlowLayout.h"

@interface ZNGTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property (weak, nonatomic) IBOutlet UIView *confirmedView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelCollectionViewHeight;

@property (nonatomic, strong) ZNGContact *contact;

@end

@implementation ZNGTableViewCell
{
    ZNGLabelCollectionViewCell *_sizingCell;
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)configureCellWithContact:(ZNGContact *)contact
{
    self.contact = contact;
    
    self.labelCollectionView.delegate = self;
    self.labelCollectionView.dataSource = self;
    UINib *cellNib = [ZNGLabelCollectionViewCell nib];
    [self.labelCollectionView registerNib:cellNib forCellWithReuseIdentifier:[ZNGLabelCollectionViewCell cellReuseIdentifier]];
//    self.labelCollectionView.collectionViewLayout = [[ZNGLabelCollectionViewFlowLayout alloc] init];

    // get a cell as template for sizing
    _sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
    
    self.contactName.text = [self contactNameForContact:contact];
    self.lastMessage.text = contact.lastMessage.body;
    self.dateLabel.attributedText = [[ZNGTimestampFormatter sharedFormatter] attributedTimestampForDate:contact.lastMessage.createdAt];

    if ([contact.labels count] > 0) {
        [self.labelCollectionView reloadData];
    }
    
    if (contact.isConfirmed) {
        self.confirmedView.backgroundColor = [UIColor grayColor];
    } else {
        self.confirmedView.backgroundColor = [UIColor greenColor];
    }
}

- (NSString *)contactNameForContact:(ZNGContact *)contact
{
    NSString *title = [contact title];
    NSString *firstName = [contact firstName];
    NSString *lastName = [contact lastName];
    
    if(firstName.length < 1 && lastName.length < 1)
    {
        NSString *phoneNumber = [contact phoneNumber];
        if (phoneNumber) {
            return phoneNumber;
        } else {
            return @"Anonymous User";
        }
    }
    else
    {
        NSString *name = @"";
        
        if(title.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", title]];
        }
        if(firstName.length > 0)
        {
            name = [name stringByAppendingString:[NSString stringWithFormat:@"%@ ", firstName]];
        }
        if(lastName.length > 0)
        {
            name = [name stringByAppendingString:lastName];
        }
        return name;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.contact.labels count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGLabel *label = [self.contact.labels objectAtIndex:indexPath.item];
    ZNGLabelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ZNGLabelCollectionViewCell cellReuseIdentifier] forIndexPath:indexPath];
    [cell configureCellWithLabel:label];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGLabel *label = [self.contact.labels objectAtIndex:indexPath.item];
    [_sizingCell configureCellWithLabel:label];
    return [_sizingCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5.0;
}

@end
