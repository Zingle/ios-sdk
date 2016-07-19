//
//  ZNGConversationToolbarContentView.h
//  Pods
//
//  Created by Jason Neel on 7/18/16.
//
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

@interface ZNGConversationToolbarContentView : JSQMessagesToolbarContentView

@property (nonatomic, strong, nullable) IBOutlet UIButton * templateButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * customFieldButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * automationButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * imageButton;
@property (nonatomic, strong, nullable) IBOutlet UIButton * noteButton;

@end
