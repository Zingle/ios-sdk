//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZingleSDK.h"
#import "ZNGMessageEntryView.h"

@interface ZNGConversationViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, ZNGMessageEntryDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *oMessageEntryOutterview;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryMaxHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryMinimumHeight;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oInitialLoadActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *oTableView;

@property (weak, nonatomic) IBOutlet ZNGMessageEntryView *oMessageEntryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oBottomLayoutGuideConstraint;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oSendingActivityIndicator;
- (IBAction)didTouchSendMessageButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *oSendButton;

@property (weak) NSTimer *pollingTimer;
@property (assign, nonatomic)NSUInteger lastTextLength;

@property (nonatomic, strong) ZNGConversation *conversation;

@end

@implementation ZNGConversationViewController

- (id)initWithConversation:(ZNGConversation *)conversation
{
    NSBundle *bundle = [NSBundle bundleForClass:ZingleSDK.class];
    self = (ZNGConversationViewController *)[[UIStoryboard storyboardWithName:@"Zingle" bundle:bundle] instantiateInitialViewController];
    
    if (self) {
        _conversation = conversation;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.oTableView.delegate        = self;
    self.oTableView.dataSource      = self;
    
    self.conversation.delegate = self;
    
    [self setupMessageEntry];
    
    self.oTableView.transform = CGAffineTransformMakeScale(1, -1);
    
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
    
    [self markMessageAsRead:@1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)markMessageAsRead:(NSNumber *)messageID {


}

- (void)setupMessageEntry{
    self.oMessageEntryOutterview.backgroundColor = [UIColor clearColor];
    
    self.oSendButton.enabled                    = NO;
    self.oMessageEntryView.delegate             = self;
    self.oMessageEntryView.backgroundColor      = [UIColor whiteColor];
    
    self.oMessageEntryView.textView.scrollEnabled = NO;
    
    NSString* initialText = self.oMessageEntryView.text;
    
    CGSize minimumSize                          = [self.oMessageEntryView sizeThatFits:CGSizeMake(self.oMessageEntryView.frame.size.width, MAXFLOAT)];
    self.oMessageEntryMinimumHeight.constant    = minimumSize.height;
    self.oMessageEntryHeight.constant           = minimumSize.height;
    
    const int numLines = 5;
    NSString* testString        = [@"" stringByPaddingToLength:numLines * 2 - 1 withString: @"M\n" startingAtIndex:0];
    self.oMessageEntryView.text = testString;
    CGSize maxSize              = [self.oMessageEntryView sizeThatFits:CGSizeMake(self.oMessageEntryView.frame.size.width, MAXFLOAT)];
    self.oMessageEntryMaxHeight.constant        = maxSize.height;
    
    self.oMessageEntryView.text = initialText;
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.oInitialLoadActivityIndicator startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopPollingTimer];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ZNGConversationDelegate

- (void)messagesUpdated
{
    [self.oTableView reloadData];
}

#pragma mark - UITableviewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

- (UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversation.messages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    
    ZNGMessage* message = self.conversation.messages[indexPath.row];
    if([self messageModelIsMyMessage:message]){
        cell = [tableView dequeueReusableCellWithIdentifier:@"MessagingMyMessagesCell"];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"MessagingOtherMessagesCell"];
    }
    return cell;
}

#pragma mark - MessageEntryDelegate
- (void)messageEntryTextDidChange:(ZNGMessageEntryView *)messageEntryView
{
    
    CGFloat newHeight       = [messageEntryView sizeThatFits:CGSizeMake(messageEntryView.frame.size.width, MAXFLOAT)].height;
    CGFloat currentHeight   = messageEntryView.frame.size.height;
    
    if((messageEntryView.text.length > self.lastTextLength && floorf(newHeight) > floorf(currentHeight)) ||
       (messageEntryView.text.length < self.lastTextLength && floorf(newHeight) < floorf(currentHeight)))
    {
        self.oMessageEntryHeight.constant = newHeight;
        
        if(newHeight >= self.oMessageEntryMaxHeight.constant && messageEntryView.text.length > self.lastTextLength){
            
            if(self.oMessageEntryView.textView.scrollEnabled == NO){
                self.oMessageEntryView.textView.scrollEnabled = YES;
            }
        }
        else if(self.oMessageEntryView.textView.scrollEnabled == YES){
            self.oMessageEntryView.textView.scrollEnabled = NO;
        }
    }
    
    self.oSendButton.enabled = [messageEntryView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;
    
    self.lastTextLength = messageEntryView.text.length;
}

#pragma mark - Utility
- (BOOL)messageModelIsMyMessage:(ZNGMessage*)message
{
    return [message.communicationDirection isEqualToString:@"outbound"];
}

#pragma mark - Actions
- (IBAction)didTouchSendMessageButton:(id)sender
{
    self.oSendButton.enabled = NO;
    [self.oSendingActivityIndicator startAnimating];
    
    // send the messages
    
    // on completion
    /**
     self.oSendButton.enabled = YES;
     [self.oSendingActivityIndicator stopAnimating];
     
     if(error != nil){
     [self showErrorAndLogIfNeeded:error];
     }
     else{
     [self.pagingViewModel insertUniqueItem:messageModel atIndex:0];
     
     [self.oTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     
     self.oMessageEntryView.text = @"";
     [self messageEntryTextDidChange:self.oMessageEntryView];
     
     }
     
     */
}

#pragma mark - Timer Long Poll
- (void)startPollingTimer
{
    // Cancel a preexisting timer.
    [self.pollingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:30
                                                      target:self selector:@selector(refresh)
                                                    userInfo:nil repeats:YES];
    self.pollingTimer = timer;
}

- (void)stopPollingTimer
{
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)refresh
{
    
}

@end
