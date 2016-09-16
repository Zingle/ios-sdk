//
//  ZNGTableViewCell.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGTableViewCell.h"
#import "ZNGLabel.h"
#import "ZNGLabelCollectionViewCell.h"
#import "ZNGLabelCollectionViewFlowLayout.h"
#import "UIImage+ZingleSDK.h"
#import "UIColor+ZingleSDK.h"
#import "JSQMessagesTimestampFormatter.h"

@interface ZNGTableViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UIView * unconfirmedCircle;

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
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    self.contactName.textColor = [UIColor colorFromHexString:@"#333333"];
    self.lastMessage.textColor = [UIColor colorFromHexString:@"#595959"];
    
    self.labelCollectionView.collectionViewLayout = [[ZNGLabelCollectionViewFlowLayout alloc] init];
    ZNGLabelCollectionViewFlowLayout *flow = (ZNGLabelCollectionViewFlowLayout *)self.labelCollectionView.collectionViewLayout;
    flow.estimatedItemSize = CGSizeMake(1, 1);
    [self.labelCollectionView setScrollEnabled:NO];
}

- (JSQMessagesTimestampFormatter *) timestampFormatter
{
    if (_timestampFormatter == nil) {
        return [JSQMessagesTimestampFormatter sharedFormatter];
    }
    
    return _timestampFormatter;
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
    self.placeholderView.hidden = YES;
    
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
            self.dateLabel.attributedText = [self.timestampFormatter attributedTimestampForDate:self.contact.lastMessage.createdAt];
            self.dateLabel.textColor = [UIColor zng_lightBlue];
        } else {
            self.lastMessage.text = @" ";
            self.dateLabel.attributedText = [[NSAttributedString alloc] initWithString:@" "];
        }
        
        if (self.contact.isConfirmed) {
            self.unconfirmedCircle.hidden = YES;
        } else {
            if (self.contact.lastMessage.createdAt) {
                NSTimeInterval distanceBetweenDates = [self.contact.lastMessage.createdAt timeIntervalSinceNow];
                
                if (distanceBetweenDates < -500) {
                    self.unconfirmedCircle.tintColor = [UIColor zng_unconfirmedMessageRed];
                } else {
                    self.unconfirmedCircle.tintColor = [UIColor zng_blue];
                }
                
                self.unconfirmedCircle.hidden = NO;
            }
            
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
    self.contactName.text = @" ";
    
    self.lastMessage.text = @" ";
    
    self.dateLabel.attributedText = [[NSAttributedString alloc] initWithString:@" "];
    
    self.unconfirmedCircle.hidden = YES;

    self.placeholderView.hidden = NO;
    
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

@end
