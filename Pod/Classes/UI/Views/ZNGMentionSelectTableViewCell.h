//
//  ZNGMentionSelectTableViewCell.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/8/20.
//

#import <UIKit/UIKit.h>

@class ZNGAvatarImageView;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGMentionSelectTableViewCell : UITableViewCell

@property (nonatomic, strong, nullable) IBOutlet ZNGAvatarImageView * avatarView;
@property (nonatomic, strong, nullable) IBOutlet UILabel * teamEmojiLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel * nameLabel;

@end

NS_ASSUME_NONNULL_END
