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
#import "UIImage+ZingleSDK.h"
#import "UIFont+OpenSans.h"
#import "ZNGContactClient.h"

@interface ZNGTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property (weak, nonatomic) IBOutlet UIView *confirmedView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) NSString *serviceId;

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

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.contactName.textColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
    self.contactName.font = [UIFont openSansSemiboldFontOfSize:12.0f];
    
    self.lastMessage.textColor = [UIColor colorWithRed:89/255.0f green:89/255.0f blue:89/255.0f alpha:1.0f];
    self.lastMessage.font = [UIFont openSansFontOfSize:12.0f];
    
    self.dateLabel.textColor = [UIColor colorWithRed:70/255.0f green:161/255.0f blue:223/255.0f alpha:1.0];
    self.dateLabel.font = [UIFont openSansBoldFontOfSize:12.0f];
    
    self.labelCollectionView.collectionViewLayout = [[ZNGLabelCollectionViewFlowLayout alloc] init];
    ZNGLabelCollectionViewFlowLayout *flow = (ZNGLabelCollectionViewFlowLayout *)self.labelCollectionView.collectionViewLayout;
    flow.estimatedItemSize = CGSizeMake(1, 1);
    [self.labelCollectionView setScrollEnabled:NO];
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    
    self.labelCollectionView.frame = CGRectMake(0, 0, targetSize.width, MAXFLOAT);
    [self.labelCollectionView layoutIfNeeded];

    CGSize cellSize = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    CGSize collectionViewSize = [self.labelCollectionView.collectionViewLayout collectionViewContentSize];
    
    return CGSizeMake(cellSize.width, cellSize.height + collectionViewSize.height);
}

- (void)configureCellWithContact:(ZNGContact *)contact withServiceId:(NSString *)serviceId
{
    if ([contact isKindOfClass:[NSNull class]]) {
        self.contact = nil;
        self.serviceId = nil;
        [self configureBlankCell];
    } else {
        self.contact = contact;
        self.serviceId = serviceId;
        self.contactName.text = [self.contact fullName];
        
        if (self.contact.lastMessage.body.length > 0) {
            self.lastMessage.text = self.contact.lastMessage.body;
            self.dateLabel.attributedText = [[ZNGTimestampFormatter sharedFormatter] attributedTimestampForDate:self.contact.lastMessage.createdAt];
        } else {
            self.lastMessage.text = @" ";
            self.dateLabel.attributedText = [[NSAttributedString alloc] initWithString:@" "];
        }
        
        if (self.contact.isConfirmed) {
            self.confirmedView.backgroundColor = [UIColor clearColor];
        } else {
            self.confirmedView.backgroundColor = [UIColor colorFromHexString:@"#02CE68"];
        }
        
        self.starButton.hidden = NO;
        if (self.contact.isStarred) {
            [self.starButton setImage:[UIImage zng_starredImage] forState:UIControlStateNormal];
        } else {
            [self.starButton setImage:[UIImage zng_unstarredImage] forState:UIControlStateNormal];
        }
        
        if ([self.contact.labels count] > 0) {
            self.labelCollectionView.hidden = NO;
            self.labelCollectionView.delegate = self;
            self.labelCollectionView.dataSource = self;
            self.labelCollectionView.userInteractionEnabled = NO;
            UINib *cellNib = [ZNGLabelCollectionViewCell nib];
            [self.labelCollectionView registerNib:cellNib forCellWithReuseIdentifier:[ZNGLabelCollectionViewCell cellReuseIdentifier]];
            _sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
            [self.labelCollectionView reloadData];
            [self setNeedsDisplay];
        }
        [self.contentView layoutIfNeeded];
    }
}

- (void)configureBlankCell
{
    self.contactName.text = @"Loading contact...";
    self.lastMessage.text = @"Loading message...";
    self.dateLabel.attributedText = [[NSAttributedString alloc] initWithString:@"..."];
    self.confirmedView.backgroundColor = [UIColor clearColor];
    self.starButton.hidden = YES;
    self.labelCollectionView.hidden = YES;
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

- (IBAction)starButtonPressed:(id)sender
{
    self.starButton.enabled = NO;

    NSNumber *starParam = self.contact.isStarred ? @NO : @YES;
    if (self.contact.isStarred) {
        self.contact.isStarred = NO;
        [self.starButton setImage:[UIImage zng_unstarredImage] forState:UIControlStateNormal];
    } else {
        self.contact.isStarred = YES;
        [self.starButton setImage:[UIImage zng_starredImage] forState:UIControlStateNormal];
    }
    NSDictionary *params = @{@"is_starred" : starParam };
    [ZNGContactClient updateContactWithId:self.contact.contactId withServiceId:self.serviceId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        self.starButton.enabled = YES;
        self.contact = contact;
    } failure:^(ZNGError *error) {
        self.starButton.enabled = YES;
    }];
}

@end
