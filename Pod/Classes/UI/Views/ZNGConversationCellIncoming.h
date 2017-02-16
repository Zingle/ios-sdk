//
//  ZNGConversationCellIncoming.h
//  Pods
//
//  Created by Jason Neel on 12/22/16.
//
//

#import <JSQMessagesViewController/JSQMessagesCollectionViewCellIncoming.h>

@interface ZNGConversationCellIncoming : JSQMessagesCollectionViewCellIncoming

/**
 *  An optional UIImage used to mask a media view.  Setting this property to the normal bubble image will result in.. masking.. the media... in the shape of a bubble.  Yeah.
 */
@property (nonatomic, strong, nullable) UIImage * mediaViewMaskingImage;

@property (nonatomic, strong, nullable) IBOutlet NSLayoutConstraint * timeOffScreenConstraint;
@property (nonatomic, strong, nullable) IBOutlet UILabel * exactTimeLabel;

@end
