//
//  ZNGConversationViewController.m
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ZingleSDK.h"
#import "ZNGConversationViewController.h"
#import "ZNGMessageView.h"
#import "ZNGConversation.h"
#import "ZNGService.h"
#import "ZNGMessage.h"
#import "ZNGMessageCorrespondent.h"

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
@property (nonatomic) BOOL wasAtBottom;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGPoint contentOffset;
@property (weak) NSTimer *pollingTimer;

@end

@implementation ZNGConversationViewController

- (id)initWithChannelTypeName:(NSString *)channelTypeName to:(NSString *)to
{
    if( self = [super init] ) {
        
        ZNGService *service = [ZingleSDK sharedSDK].currentService;
        ZNGChannelType *channelType = [service firstChannelTypeWithClass:@"UserDefinedChannel" andDisplayName:channelTypeName];
        
        if( channelType == nil ) {
            [NSException raise:@"ZINGLE_SDK_INVALID_CHANNEL_TYPE" format:@"Channel type supplied does not exist for current Service."];
        }
        
        ZNGMessageCorrespondent *correspondent = [[ZNGMessageCorrespondent alloc] init];
        [correspondent setCorrespondentType:ZINGLE_CORRESPONDENT_TYPE_CONTACT];
        [correspondent setChannelType:channelType];
        [correspondent setChannelValue:to];
        
        self.conversation = [[ZingleSDK sharedSDK] conversationWithService:service to:correspondent usingChannelType:channelType];
        [self initializeUI];
    }
    return self;
}

- (id)initWithChannelTypeName:(NSString *)channelTypeName from:(NSString *)from
{
    if( self = [super init] ) {
        
        ZNGService *service = [ZingleSDK sharedSDK].currentService;
        ZNGChannelType *channelType = [service firstChannelTypeWithClass:@"UserDefinedChannel" andDisplayName:channelTypeName];
        
        if( channelType == nil ) {
            [NSException raise:@"ZINGLE_SDK_INVALID_CHANNEL_TYPE" format:@"Channel type supplied does not exist for current Service."];
        }
        
        ZNGMessageCorrespondent *correspondent = [[ZNGMessageCorrespondent alloc] init];
        [correspondent setCorrespondentType:ZINGLE_CORRESPONDENT_TYPE_CONTACT];
        [correspondent setChannelType:channelType];
        [correspondent setChannelValue:from];
        
        self.conversation = [[ZingleSDK sharedSDK] conversationWithService:service from:correspondent usingChannelType:channelType];
        [self initializeUI];
    }
    return self;
}


- (id)initWithConversation:(ZNGConversation *)conversation
{
    if( self = [super init]) {

        self.conversation = conversation;
        [self initializeUI];
    }
    return self;
}

- (void)initializeUI
{
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
    
    _fromName = @"Me";
    _toName = @"Received";
    
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
 
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *cameraImage = [[UIImage imageNamed:@"camera" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraButton setImage:cameraImage forState:UIControlStateNormal];
    self.cameraButton.adjustsImageWhenHighlighted = YES;
    self.cameraButton.frame = CGRectMake(0, 0, 30, 30);
    self.cameraButton.tintColor = [UIColor grayColor];
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
    [center addObserver:self selector:@selector(keyboardClosed:) name:UIKeyboardWillHideNotification object:nil];
    self.keyboardHeight = 0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap)];
    tapGesture.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:tapGesture];
}

#pragma mark - Timer Long Poll
- (void)startPollingTimer{
    // Cancel a preexisting timer.
    [self.pollingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10
                                                      target:self selector:@selector(refresh)
                                                    userInfo:nil repeats:YES];
    self.pollingTimer = timer;
}
- (void)stopPollingTimer{
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)didDoubleTap
{
    [self refresh];
}

- (void)keyboardOnScreen:(NSNotification *)notification
{
    self.wasAtBottom = [self isScrolledToBottom];
    
    NSDictionary *info = notification.userInfo;
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame = [value CGRectValue];
    self.keyboardHeight = [self.view convertRect:rawFrame fromView:nil].size.height;
    
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [UIView setAnimationCurve:curve];
                         [self refreshDisplay];
                     }
                     completion:nil];
    

}

- (void)keyboardClosed:(NSNotification *)notification
{
    self.keyboardHeight = 0;
    
    UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [UIView setAnimationCurve:curve];
                         [self refreshDisplay];
                     }
                     completion:nil];
}

- (void)sendButtonPressed:(UIButton *)sender
{
    self.replyButton.enabled = NO;
    self.responseText.editable = NO;
    
    self.sendActivity.frame = self.replyButton.frame;
    self.sendActivity.alpha = 1;
    [self.sendActivity startAnimating];
    [self.responseView bringSubviewToFront:self.sendActivity];
    self.replyButton.alpha = 0;
    
    [self.conversation sendMessageWithBody:self.responseText.text completionBlock:^{
        
        self.responseText.text = @"";
        
        [self performSelector:@selector(refresh) withObject:nil afterDelay:1];
        
        
    } errorBlock:^(NSError *error) {
        
        self.responseText.text = @"";
        self.responseText.editable = YES;
        self.replyButton.enabled = YES;
        [self.sendActivity stopAnimating];
        self.sendActivity.alpha = 0;
        self.replyButton.alpha = 1;
        
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
    
    self.sendActivity.frame = self.replyButton.frame;
    self.sendActivity.alpha = 1;
    [self.sendActivity startAnimating];
    [self.responseView bringSubviewToFront:self.sendActivity];
    self.replyButton.alpha = 0;

    
    [picker dismissViewControllerAnimated:YES completion:^{
        self.replyButton.enabled = NO;
        self.responseText.editable = NO;
        
        [self.conversation sendMessageWithImage:chosenImage completionBlock:^{
            
            self.responseText.editable = YES;
            
            [self performSelector:@selector(refresh) withObject:nil afterDelay:1];
            
        } errorBlock:^(NSError *error) {
            
            self.responseText.editable = YES;
            self.responseText.editable = YES;
            self.replyButton.enabled = YES;
            [self.sendActivity stopAnimating];
            self.sendActivity.alpha = 0;
            self.replyButton.alpha = 1;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error sending your message, please try again later." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
            
            [alert show];
        }];
    }];
    
    
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self refreshDisplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.scrollView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.responseView];
    
    // Wipe all CC data when app enters background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPollingTimer)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Wipe all CC data when app enters background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPollingTimer)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
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

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopPollingTimer];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh
{
    if( self.conversation == nil ) {
        [NSException raise:@"Conversation View Controller requires initialization with a Conversation object." format:@"Missing Conversation Object"];
    }
    
    self.wasAtBottom = [self isScrolledToBottom];
    self.contentSize = self.scrollView.contentSize;
    self.contentOffset = self.scrollView.contentOffset;
    
    [self clear];
    
    [self startPollingTimer];
    
    NSArray *messages = [self.conversation messages];
    for( ZNGMessage *message in messages ) {
        
        [self addMessage:message withDirection:[self.conversation messageDirectionFor:message]];
    }
    
    [self scrollToLastOffest];
    
    if (self.contentSize.height != self.scrollView.contentSize.height) {
        [self scrollToBottom:YES];
    }
    
    self.view.backgroundColor = self.containerBackgroundColor;
    
    self.responseText.editable = YES;
    self.replyButton.enabled = YES;
    [self.sendActivity stopAnimating];
    self.sendActivity.alpha = 0;
    self.replyButton.alpha = 1;
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
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.bottomY + 50);
    
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    CGSize textViewSize = [self.responseText sizeThatFits:CGSizeMake(self.view.frame.size.width - 115, FLT_MAX)];
    
    self.responseView.frame = CGRectMake(-2, self.view.frame.size.height - textViewSize.height - 14 - self.keyboardHeight, self.view.frame.size.width+4, textViewSize.height + 16);
    

    self.replyButton.frame = CGRectMake(self.responseView.frame.size.width - self.replyButton.frame.size.width - 10, 8, self.replyButton.frame.size.width, self.replyButton.frame.size.height);
    self.sendActivity.frame = self.replyButton.frame;
    
    self.cameraButton.frame = CGRectMake(8, 8, self.cameraButton.frame.size.width, self.cameraButton.frame.size.height);
    
    
    self.responseText.frame = CGRectMake(self.responseText.frame.origin.x, self.responseText.frame.origin.y, self.replyButton.frame.origin.x - self.responseText.frame.origin.x - 15, textViewSize.height);
    
    self.responseTextBackground.frame = CGRectMake(self.responseTextBackground.frame.origin.x, self.responseTextBackground.frame.origin.y, self.responseText.frame.size.width + 14, self.responseText.frame.size.height);
    
    self.scrollView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.responseView.frame.size.height - self.keyboardHeight - [UIApplication sharedApplication].statusBarFrame.size.height);
    
    if( self.wasAtBottom ) {
        [self scrollToBottom:NO];
    }
}

- (void)scrollToLastOffest{
    if( self.bottomY > self.scrollView.frame.size.height ) {
        //        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:self.contentOffset animated:NO];
    }
}

- (void)scrollToBottom:(BOOL)animated
{
    if( self.bottomY > self.scrollView.frame.size.height ) {
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:bottomOffset animated:animated];
    }
}

- (BOOL)isScrolledToBottom
{
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    return (self.scrollView.contentOffset.y == bottomOffset.y);
}

- (void)clear
{
    for( ZNGMessageView *messageView in self.messages )
    {
        [messageView removeFromSuperview];
    }
    
    self.messages = [[NSMutableArray alloc] init];
    self.bottomY = 10;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 50);
}


- (void)addActivityView
{
    
    self.loadActivity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, self.bottomY, self.scrollView.frame.size.width, 50)];
    [self.loadActivity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];

//    self.bottomY = self.bottomY + self.activity.frame.size.height;
//
//    int contentHeight = (self.bottomY < self.frame.size.height) ? self.frame.size.height : self.bottomY + 15;

//    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight);

    [self.loadActivity startAnimating];
    [self.scrollView addSubview:self.loadActivity];
}



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
