//
//  ZNGConversationViewController.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZNGConversationViewController.h"
#import "ZNGMessageView.h"
#import "ZNGConversation.h"
#import "ZNGService.h"
#import "ZNGMessage.h"

int const ZINGLE_ARROW_POSITION_BOTTOM = 0;
int const ZINGLE_ARROW_POSITION_SIDE = 1;

@interface ZNGConversationViewController ()

@property (nonatomic) int bottomY, keyboardHeight;

@property (strong, nonatomic) UIView *responseView;
@property (strong, nonatomic) UITextView *responseText;
@property (strong, nonatomic) UITextField *responseTextBackground;
@property (strong, nonatomic) UIButton *replyButton, *cameraButton;

@property (nonatomic, retain) NSMutableArray *messages;
@property (nonatomic, retain) UIActivityIndicatorView *sendActivity, *loadActivity;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIColor *containerBackgroundColor;

@end

@implementation ZNGConversationViewController

- (id)initWithConversation:(ZNGConversation *)conversation
{
    if( self = [super init]) {

        self.conversation = conversation;
        
        self.scrollView = [[UIScrollView alloc] init];
        
        self.messages = [[NSMutableArray alloc] init];
        self.bottomY = 10;
        self.scrollView.backgroundColor = [UIColor clearColor];
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        
        _containerBackgroundColor = [UIColor whiteColor];
        
        _inboundBackgroundColor = [UIColor colorWithRed:225.0f/255.0f green:225.0f/255.0f blue:225.0f/255.0f alpha:1.0f];
        _outboundBackgroundColor = [UIColor colorWithRed:229.0f/255.0f green:245.0f/255.0f blue:252.0f/255.0f alpha:1.0f];
        _eventBackgroundColor = [UIColor colorWithRed:182.0f/255.0f green:184.0f/255.0f blue:186.0f/255.0f alpha:1.0f];
        
        _inboundTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        _outboundTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        _eventTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        _authorTextColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        
        _messageHorziontalMargin = 25;
        _messageVerticalMargin = 8;
        _messageIndentAmount = 40;
        _bodyPadding = 14;
        _cornerRadius = 10;
        _arrowOffset = 10;
        _arrowSize = CGSizeMake(20, 10);
        
        self.responseView = [[UIView alloc] init];
        self.responseView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:0.75];
        self.responseView.layer.borderWidth= 1;
        self.responseView.layer.borderColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5].CGColor;
    
        self.sendActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.sendActivity.alpha = 0;
        [self.responseView addSubview:self.sendActivity];
        
        self.replyButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.replyButton setTitle:@"Send" forState:UIControlStateNormal];
        self.replyButton.frame = CGRectMake(0, 0, 50, 30);
        [self.replyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//        self.cameraButton.
        [self.replyButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.replyButton.enabled = NO;
        [self.responseView addSubview:self.replyButton];
        
        
        self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
        self.cameraButton.adjustsImageWhenHighlighted = YES;
        self.cameraButton.frame = CGRectMake(0, 0, 30, 30);
        [self.cameraButton addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.responseView addSubview:self.cameraButton];
        
        self.responseTextBackground = [[UITextField alloc] initWithFrame:CGRectMake(43, 7, 495, 30)];
        [self.responseTextBackground setBorderStyle:UITextBorderStyleRoundedRect];
        [self.responseView addSubview:self.responseTextBackground];
        
        self.responseText = [[UITextView alloc] initWithFrame:CGRectMake(50, 7, 479, 30)];
        self.responseText.backgroundColor = [UIColor clearColor];
        self.responseText.delegate = self;
        [self.responseView addSubview:self.responseText];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(keyboardClosed) name:UIKeyboardWillHideNotification object:nil];
        self.keyboardHeight = 0;
    }
    return self;
}

- (void)keyboardOnScreen:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame = [value CGRectValue];
    self.keyboardHeight = [self.view convertRect:rawFrame fromView:nil].size.height;
    
    [self refreshDisplay];
}

- (void)keyboardClosed
{
    self.keyboardHeight = 0;
    [self refreshDisplay];
}

- (void)sendButtonPressed:(UIButton *)sender
{
    self.sendActivity.frame = sender.frame;
    self.sendActivity.alpha = 1;
    self.replyButton.alpha = 0;
    
    [self.sendActivity startAnimating];
    [self.responseView bringSubviewToFront:self.sendActivity];
    
    [self.responseView resignFirstResponder];
    self.responseText.editable = NO;
    
    [self.conversation sendMessageWithBody:self.responseText.text completionBlock:^{
        
        self.responseText.editable = YES;
        self.responseText.text = @"";
        self.replyButton.alpha = 1;
        self.sendActivity.alpha = 0;
        
        [self refresh];
        
    } errorBlock:^(NSError *error) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your message, please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        
        [alert show];
    }];
}

- (void)cameraButtonPressed:(id)sender
{
    [self.responseView resignFirstResponder];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Send Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take a Picture", @"Choose a Picture", nil];

    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex == [actionSheet cancelButtonIndex] ) {
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    if( buttonIndex == 0 )
    {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else if( buttonIndex == 1)
    {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    self.responseText.editable = NO;
    [picker dismissViewControllerAnimated:YES completion:^{
        
        self.sendActivity.frame = self.replyButton.frame;
        self.sendActivity.alpha = 1;
        self.replyButton.alpha = 0;
        
        [self.sendActivity startAnimating];
        [self.responseView bringSubviewToFront:self.sendActivity];
        self.responseText.editable = NO;
        
        [self.conversation sendMessageWithImage:chosenImage completionBlock:^{
            
            self.responseText.editable = YES;
            self.replyButton.alpha = 1;
            self.sendActivity.alpha = 0;
            
            [self refresh];
            
        } errorBlock:^(NSError *error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your message, please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
            
            [alert show];
        }];
    }];
    
    
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.replyButton.enabled = ![textView.text isEqualToString:@""];
    [self refreshDisplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.responseView];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    self.containerBackgroundColor = backgroundColor;
    if( self.view != nil && [self.view superview] != nil ) {
        self.view.backgroundColor = self.containerBackgroundColor;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refresh];
    [super viewDidAppear:animated];
}

- (void)refresh
{
    if( self.conversation == nil ) {
        [NSException raise:@"Conversation View Controller requires initialization with a Conversation object." format:@"Missing Conversation Object"];
    }
    [self clear];
    
    NSArray *messages = [self.conversation messages];
    for( ZNGMessage *message in messages ) {
        
        [self addMessage:message withDirection:[self.conversation messageDirectionFor:message]];
    }
    
    self.view.backgroundColor = self.containerBackgroundColor;
    
    [self scrollToBottom:NO];
}

 - (void)setInboundBackgroundColor:(UIColor *)inboundBackgroundColor
{
    _inboundBackgroundColor = inboundBackgroundColor;
    [self refreshMessages];
}

- (void)setOutboundBackgroundColor:(UIColor *)outboundBackgroundColor
{
    _outboundBackgroundColor = outboundBackgroundColor;
    [self refreshMessages];
}

- (void)setInboundTextColor:(UIColor *)inboundTextColor
{
    _inboundTextColor = inboundTextColor;
    [self refreshMessages];
}

- (void)setOutboundTextColor:(UIColor *)outboundTextColor
{
    _outboundTextColor = outboundTextColor;
    [self refreshMessages];
}

- (void)setEventBackgroundColor:(UIColor *)eventBackgroundColor
{
    _eventBackgroundColor = eventBackgroundColor;
    [self refreshMessages];
}

- (void)setEventTextColor:(UIColor *)eventTextColor
{
    _eventTextColor = eventTextColor;
    [self refreshMessages];
}

 - (void)setMessageHorziontalMargin:(int)messageHorziontalMargin
{
    _messageHorziontalMargin = messageHorziontalMargin;
    [self refreshMessages];
}

- (void)setMessageVerticalMargin:(int)messageVerticalMargin
{
    _messageVerticalMargin = messageVerticalMargin;
    [self refreshMessages];
}

- (void)setMessageIndentAmount:(int)messageIndentAmount
{
    _messageIndentAmount = messageIndentAmount;
    [self refreshMessages];
}

- (void)setBodyPadding:(int)bodyPadding
{
    _bodyPadding = bodyPadding;
    [self refreshMessages];
}

- (void)setCornerRadius:(int)cornerRadius
{
    _cornerRadius = cornerRadius;
    [self refreshMessages];
}

- (void)setArrowOffset:(int)arrowOffset
{
    _arrowOffset = arrowOffset;
    [self refreshMessages];
}

- (void)setArrowSize:(CGSize)arrowSize
{
    _arrowSize = arrowSize;
    [self refreshMessages];
}

- (void)setArrowPosition:(int)arrowPosition
{
    _arrowPosition = arrowPosition;
    [self refreshMessages];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    _messageFont = messageFont;
    [self refreshMessages];
}

- (void)setAuthorTextColor:(UIColor *)authorTextColor
{
    _authorTextColor = authorTextColor;
    [self refreshMessages];
}

- (void)setArrowBias:(int)arrowBias
{
    _arrowBias = arrowBias;
    [self refreshMessages];
}

- (ZNGMessageView *)addMessage:(ZNGMessage *)message withDirection:(NSString *)direction
{
    ZNGMessageView *messageView = [[ZNGMessageView alloc] initWithViewController:self];
    messageView.frame = CGRectMake(0, self.bottomY, self.scrollView.frame.size.width, 150);
    [messageView setMessage:message withDirection:direction];
    
    [self.messages addObject:messageView];
    
    self.bottomY = self.bottomY + messageView.frame.size.height;
    
    int contentHeight = (self.bottomY < self.scrollView.frame.size.height) ? self.scrollView.frame.size.height : self.bottomY + 15;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, contentHeight);
    [self.scrollView addSubview:messageView];
    
    return messageView;
}

- (void)refreshMessages
{
    self.bottomY = 10;
    for( ZNGMessageView *messageView in self.messages )
    {
        messageView.frame = CGRectMake(messageView.frame.origin.x, messageView.frame.origin.y, self.scrollView.frame.size.width, messageView.frame.size.height);
        
        [messageView refresh];
        
        self.bottomY = self.bottomY + messageView.frame.size.height;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.bottomY + 30);
    
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    CGSize textViewSize = [self.responseText sizeThatFits:CGSizeMake(self.view.frame.size.width - 115, FLT_MAX)];
    
    self.responseView.frame = CGRectMake(-2, self.view.frame.size.height - textViewSize.height - 14 - self.keyboardHeight, self.view.frame.size.width+4, textViewSize.height + 16);
    

    self.replyButton.frame = CGRectMake(self.responseView.frame.size.width - self.replyButton.frame.size.width - 10, 8, self.replyButton.frame.size.width, self.replyButton.frame.size.height);
    
    self.cameraButton.frame = CGRectMake(8, 8, self.cameraButton.frame.size.width, self.cameraButton.frame.size.height);
    
    
    self.responseText.frame = CGRectMake(self.responseText.frame.origin.x, self.responseText.frame.origin.y, self.replyButton.frame.origin.x - self.responseText.frame.origin.x - 15, textViewSize.height);
    
    self.responseTextBackground.frame = CGRectMake(self.responseTextBackground.frame.origin.x, self.responseTextBackground.frame.origin.y, self.responseText.frame.size.width + 14, self.responseText.frame.size.height);
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - self.responseView.frame.size.height - self.keyboardHeight);
    
    [self scrollToBottom:YES];
}

- (void)scrollToBottom:(BOOL)animated
{
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:bottomOffset animated:animated];
}

- (void)clear
{
    for( ZNGMessageView *messageView in self.messages )
    {
        [messageView removeFromSuperview];
    }
    [self.sendActivity removeFromSuperview];
    self.messages = [[NSMutableArray alloc] init];
    self.bottomY = 10;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height);
}

//
//- (void)addActivityView
//{
//    
//    self.activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, self.bottomY, self.frame.size.width, 50)];
//    [self.activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
//
//    self.bottomY = self.bottomY + self.activity.frame.size.height;
//
//    int contentHeight = (self.bottomY < self.frame.size.height) ? self.frame.size.height : self.bottomY + 15;
//
//    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight);
//
//    [self.activity startAnimating];
//    [self addSubview:self.activity];
//}
//


- (void)viewDidLayoutSubviews {
    self.scrollView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    
    [self refreshMessages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
