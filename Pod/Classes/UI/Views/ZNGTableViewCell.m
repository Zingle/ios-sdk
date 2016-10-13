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
#import "ZingleSDK/ZingleSDK-Swift.h"

@interface ZNGTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *contactName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UIImageView * unconfirmedCircle;

@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) NSString *serviceId;

@end

@implementation ZNGTableViewCell
{
    ZNGLabelCollectionViewCell *_sizingCell;
    UIImage * unconfirmedImage;
    UIImage * unconfirmedLateImage;
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
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    unconfirmedImage = [UIImage imageNamed:@"unconfirmedCircle" inBundle:bundle compatibleWithTraitCollection:nil];
    unconfirmedLateImage = [UIImage imageNamed:@"unconfirmedLateCircle" inBundle:bundle compatibleWithTraitCollection:nil];
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
}

- (void)configureCellWithContact:(ZNGContact *)contact withServiceId:(NSString *)serviceId
{
    self.placeholderView.hidden = YES;
    
    self.closedShadingOverlay.hidden = !(contact.isClosed);
    
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
        } else {
            self.lastMessage.text = @" ";
        }
        
        if (self.contact.isConfirmed) {
            self.unconfirmedCircle.image = nil;
        } else {
            if (self.contact.lastMessage.createdAt) {
                NSTimeInterval distanceBetweenDates = [self.contact.lastMessage.createdAt timeIntervalSinceNow];
                
                if (distanceBetweenDates < -500) {
                    self.unconfirmedCircle.image = unconfirmedImage;
                } else {
                    self.unconfirmedCircle.image = unconfirmedLateImage;
                }
            }
        }
        
        self.labelGrid.labels = self.contact.labels;
        
        [self.contentView layoutIfNeeded];
    }
}

- (void)configureBlankCell
{
    self.contactName.text = @" ";
    
    self.lastMessage.text = @" ";
        
    self.unconfirmedCircle.tintColor = [UIColor clearColor];

    self.placeholderView.hidden = NO;
}

@end
