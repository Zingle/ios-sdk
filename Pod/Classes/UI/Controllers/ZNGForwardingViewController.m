//
//  ZNGForwardingViewController.m
//  Pods
//
//  Created by Jason Neel on 12/1/16.
//
//

#import "ZNGForwardingViewController.h"
#import "ZNGForwardingInputToolbar.h"
#import "ZNGContact.h"
#import "ZNGMessage.h"
#import "ZNGPrinter.h"
#import "ZNGService.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGHotsosClient.h"

@import SBObjectiveCWrapper;

#define kToolbarHeightKVOPath @"contentView.textView.contentSize"

enum {
    RECIPIENT_TYPE_NONE,
    RECIPIENT_TYPE_SERVICE,
    RECIPIENT_TYPE_SMS,
    RECIPIENT_TYPE_EMAIL,
    RECIPIENT_TYPE_HOTSOS,
    RECIPIENT_TYPE_PRINTER
};

@interface ZNGForwardingViewController ()

@end

@implementation ZNGForwardingViewController
{
    BOOL userHasInteracted; // Flag used to determine if we should confirm before dismissing
    BOOL serviceSupportsHotsos;
    
    ZNGHotsosClient * hotsosClient;
    NSString * selectedHotsosIssueName;
    
    ZNGPrinter * selectedPrinter;
    
    uint8_t recipientType;
    
    CGFloat initialToolbarHeight;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    initialToolbarHeight = self.toolbarHeightConstraint.constant;
    
    [self.inputToolbar addObserver:self forKeyPath:kToolbarHeightKVOPath options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    
    UITextView * textView = self.inputToolbar.contentView.textView;
    textView.text = self.message.body;
    textView.delegate = self;
    
    serviceSupportsHotsos = (([[self.activeService hotsosHostName] length]) && ([[self.activeService hotsosUserName] length]) && ([[self.activeService hotsosPassword] length]));
    
    if (serviceSupportsHotsos) {
        hotsosClient = [[ZNGHotsosClient alloc] initWithService:self.activeService];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAppearingOrDisappearing:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAppearingOrDisappearing:) name:UIKeyboardWillHideNotification object:nil];

    self.roomNumberTextField.text = [[self.contact roomFieldValue] value];
    
    // Check if we actually have a message to forward
    if ([self.message.body length] == 0) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to forward message" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        
        [self selectRecipientType:self];
    }
}

- (void) dealloc
{
    [self.inputToolbar removeObserver:self forKeyPath:kToolbarHeightKVOPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Toolbar height
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kToolbarHeightKVOPath]) {
        NSValue * oldContentSizeValue = change[NSKeyValueChangeOldKey];
        NSValue * newContentSizeValue = change[NSKeyValueChangeNewKey];
        
        if ((![oldContentSizeValue isKindOfClass:[NSValue class]]) || (![newContentSizeValue isKindOfClass:[NSValue class]])) {
            // This is probably initialization with no previous value
            return;
        }
        
        [self resizeToolbarWithDY:[newContentSizeValue CGSizeValue].height - [oldContentSizeValue CGSizeValue].height];
    }
}

- (void) resizeToolbarWithDY:(CGFloat)dy
{
    CGFloat targetHeight = self.toolbarHeightConstraint.constant + dy;
    static const CGFloat maxHeight = 400.0;
    
    // Are we getting too tall?
    if ((dy > 0.0) && (targetHeight > maxHeight)) {
        targetHeight = maxHeight;
    }
    
    // Too small?
    if ((dy < 0.0) && (targetHeight < initialToolbarHeight)) {
        targetHeight = initialToolbarHeight;
    }
    
    self.toolbarHeightConstraint.constant = targetHeight;
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

#pragma mark - Keyboard handling
- (void) keyboardAppearingOrDisappearing:(NSNotification *)notification
{
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardEndFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardLocalFrame = [self.view convertRect:keyboardEndFrame fromView:nil];
    CGFloat keyboardTop = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardLocalFrame);
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    self.toolbarBottomSpaceConstraint.constant = keyboardTop;
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:duration delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState|(animationCurve << 16)) animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark - Text view
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    userHasInteracted = YES;
    return YES;
}

#pragma mark - Text field
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    userHasInteracted = YES;
    
    if (textField == self.textField) {
        BOOL shouldChange = YES;
        NSString * resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];

        if (recipientType == RECIPIENT_TYPE_SMS) {
            // Only allow phone number characters
            NSCharacterSet * phoneNumberCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-() *#+"];
            NSCharacterSet * disallowedCharacters = [phoneNumberCharacters invertedSet];
            NSRange disallowedRange = [string rangeOfCharacterFromSet:disallowedCharacters];
            shouldChange = (disallowedRange.location == NSNotFound);
        }
        
        [[self.inputToolbar sendButton] setEnabled:[self sufficientRecipientDataExistsWithRecipientString:resultString]];
        
        return shouldChange;
    } else if (textField == self.hotsosIssueTextField) {
        selectedHotsosIssueName = nil;
        [[self.inputToolbar sendButton] setEnabled:NO];
    }
    
    return YES;
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.hotsosIssueTextField) {
        // If they have selected an issue, we do not want their cursor entering the field unless they do so by hitting clear
        return (selectedHotsosIssueName == nil);
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.hotsosIssueTextField) {
        [self searchForHotsosIssue];
    }
    
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    if (textField == self.hotsosIssueTextField) {
        selectedHotsosIssueName = nil;
        [[self.inputToolbar sendButton] setEnabled:NO];
    }
    
    return YES;
}

#pragma mark - Actions
- (IBAction) pressedCancel:(id)sender
{
    if (!userHasInteracted) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Cancel forwarding?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction * leave = [UIAlertAction actionWithTitle:@"Discard and exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:leave];
        
        UIAlertAction * stay = [UIAlertAction actionWithTitle:@"Continue forwarding" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:stay];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction) pressedHotsosIssueSearch:(id)sender
{
    [self searchForHotsosIssue];
}

#pragma mark - Delicious HotSOS
- (void) searchForHotsosIssue
{
    userHasInteracted = YES;
    
    NSString * term = self.hotsosIssueTextField.text;
    
    if ([term length] == 0) {
        // It should be pretty self explanatory if there is no text entered.  I'd rather not honk away with a modal alert.
        SBLogInfo(@"User pressed \"search\" in the HotSOS issue box, but there is no text entered.  Ignoring.");
        return;
    }
    
    self.issueSearchButton.hidden = YES;
    [self.issueSearchActivityIndicator startAnimating];
    
    [hotsosClient getIssuesLike:term completion:^(NSArray<NSString *> * _Nullable matchingIssueNames, NSError * _Nullable error) {
        self.issueSearchButton.hidden = NO;
        [self.issueSearchActivityIndicator stopAnimating];
        
        if (error != nil) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to search for HotSOS issues" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        } else if ([matchingIssueNames count] == 0) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"No matching HotSOS issues were found" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self chooseHotsosIssue:matchingIssueNames];
        }
    }];
}

- (void) chooseHotsosIssue:(NSArray<NSString *> *)issues
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Matching issues" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceRect = self.hotsosInputView.bounds;
    alert.popoverPresentationController.sourceView = self.hotsosInputView;
    
    for (NSString * issueName in issues) {
        UIAlertAction * action = [UIAlertAction actionWithTitle:issueName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectHotsosIssue:issueName];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self didSelectHotsosIssue:nil];
    }];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) didSelectHotsosIssue:(NSString *)issueName
{
    self.hotsosIssueTextField.text = issueName;
    selectedHotsosIssueName = issueName;
    [[self.inputToolbar sendButton] setEnabled:[self sufficientRecipientDataExists]];
    
    if ([issueName length] > 0) {
        [self.hotsosIssueTextField resignFirstResponder];
    }
}

#pragma mark - Recipient type changing
- (IBAction) selectRecipientType:(id)sender
{
    userHasInteracted = YES;
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select recipient type" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceRect = self.selectRecipientTypeButton.bounds;
    alert.popoverPresentationController.sourceView = self.selectRecipientTypeButton;
    
    UIAlertAction * sms = [UIAlertAction actionWithTitle:@"SMS" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeRecipientType:RECIPIENT_TYPE_SMS];
    }];
    [alert addAction:sms];
    
    UIAlertAction * email = [UIAlertAction actionWithTitle:@"Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeRecipientType:RECIPIENT_TYPE_EMAIL];
    }];
    [alert addAction:email];
    
    if (serviceSupportsHotsos) {
        UIAlertAction * hotsos = [UIAlertAction actionWithTitle:@"HotSOS" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeRecipientType:RECIPIENT_TYPE_HOTSOS];
        }];
        [alert addAction:hotsos];
    }
    
    for (ZNGPrinter * printer in self.activeService.printers) {
        
        if (printer.printerId == nil) {
            SBLogWarning(@"Printer does not have an ID.  Not listing as a forwarding option.");
            continue;
        }
        
        NSString * title = [NSString stringWithFormat:@"Printer: %@", printer.displayName ?: printer.printerId];
        UIAlertAction * printerAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self->selectedPrinter = printer;
            [self changeRecipientType:RECIPIENT_TYPE_PRINTER];
        }];
        [alert addAction:printerAction];
    }
    
    for (ZNGService * service in self.availableServices) {
        NSString * title = [NSString stringWithFormat:@"Service: %@", service.displayName];
        UIAlertAction * serviceAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.forwardTargetService = service;
            [self changeRecipientType:RECIPIENT_TYPE_SERVICE];
        }];
        [alert addAction:serviceAction];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) changeRecipientType:(uint8_t)newRecipientType
{
    if (recipientType == newRecipientType) {
        switch (recipientType) {
            case RECIPIENT_TYPE_SMS:
            case RECIPIENT_TYPE_EMAIL:
            case RECIPIENT_TYPE_HOTSOS:
                return;
            default:
                // Yes, we have the same general recipient type selected, but they may be moving from service 1 to service 2, etc.  Continue as normal.
                break;
        }
    }
    
    recipientType = newRecipientType;
    NSString * description;
    
    userHasInteracted |= (recipientType != RECIPIENT_TYPE_NONE);
    BOOL requiresSingleTextInput = [self recipientTypeRequiresSingleTextInput];
    
    selectedHotsosIssueName = nil;
    self.hotsosIssueTextField.text = @"";
    
    self.textField.text = @"";
    self.textField.hidden = !requiresSingleTextInput;
    self.hotsosInputView.hidden = (recipientType != RECIPIENT_TYPE_HOTSOS);
    
    switch(recipientType) {
        case RECIPIENT_TYPE_SERVICE:
            description = [NSString stringWithFormat:@"Service: %@", self.forwardTargetService.displayName ?: @""];
            break;
        case RECIPIENT_TYPE_PRINTER:
            description = [NSString stringWithFormat:@"Printer: %@", selectedPrinter.displayName ?: selectedPrinter.printerId];
            break;
        case RECIPIENT_TYPE_SMS:
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            self.textField.placeholder = @"Enter phone number";
            description = @"SMS";
            break;
        case RECIPIENT_TYPE_EMAIL:
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            self.textField.placeholder = @"Enter email address";
            description = @"Email";
            break;
        case RECIPIENT_TYPE_HOTSOS:
            description = @"HotSOS";
            break;
        default:
            description = @"Select";
    }
    
    [self.selectRecipientTypeButton setTitle:description forState:UIControlStateNormal];
    
    // Which text field wants to be first responder?  Anyone?
    if (requiresSingleTextInput) {
        [self.textField becomeFirstResponder];
        [self.textField reloadInputViews];
    } else {
        if (recipientType == RECIPIENT_TYPE_HOTSOS) {
            [self.hotsosIssueTextField becomeFirstResponder];
        } else {
            [self.textField resignFirstResponder];
            [self.hotsosIssueTextField resignFirstResponder];
        }
    }
    
    [[self.inputToolbar sendButton] setEnabled:[self sufficientRecipientDataExists]];
}

- (BOOL) recipientTypeRequiresSingleTextInput
{
    return ((recipientType == RECIPIENT_TYPE_EMAIL) || (recipientType == RECIPIENT_TYPE_SMS));
}

/**
 *  Do we have a selected recipient?
 */
- (BOOL) sufficientRecipientDataExistsWithRecipientString:(NSString *)recipientString
{
    NSString * recipient = recipientString ?: self.textField.text;
    
    if (recipientType == RECIPIENT_TYPE_EMAIL) {
        NSString * emailRegex = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
        NSPredicate * emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        return [emailTest evaluateWithObject:recipient];
    } else if (recipientType == RECIPIENT_TYPE_SMS) {
        // Check for at least five numbers
        static const NSUInteger minimumDigitsInPhoneNumber = 5;
        NSUInteger numberCount = 0;
        NSCharacterSet * numberSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        for (NSUInteger i=0; i < [recipient length]; i++) {
            if ([numberSet characterIsMember:[recipient characterAtIndex:i]]) {
                numberCount++;
                
                if (numberCount >= minimumDigitsInPhoneNumber) {
                    return YES;
                }
            }
        }
        
        SBLogDebug(@"Only found %llu numbers in the recipient field.  We require at least %llu for a phone number.", (unsigned long long)numberCount, (unsigned long long)minimumDigitsInPhoneNumber);
        return NO;
    } else if (recipientType == RECIPIENT_TYPE_HOTSOS) {
        return ([selectedHotsosIssueName length] > 0);
    } else if (recipientType == RECIPIENT_TYPE_SERVICE) {
        return (self.forwardTargetService != nil);
    } else if (recipientType == RECIPIENT_TYPE_PRINTER) {
        return (selectedPrinter != nil);
    }

    return NO;
}

- (BOOL) sufficientRecipientDataExists
{
    return [self sufficientRecipientDataExistsWithRecipientString:nil];
}

#pragma mark - Sending
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender
{
    // Unused but required delegate method
}

- (void) messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender
{
    if (![self sufficientRecipientDataExists]) {
        SBLogError(@"Insufficient recipient data exists, but the user was still able to press the forward button.  This is odd.");
        return;
    }
    
    [[[self inputToolbar] sendButton] setEnabled:NO];

    void (^success)(ZNGStatus * status) = ^void(ZNGStatus * status) {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    void (^failure)(ZNGError * error) = ^void(ZNGError * error) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to forward message" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[[self inputToolbar] sendButton] setEnabled:YES];
        }];
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    };
    
    // Accept any auto-corrections
    [self.inputToolbar.contentView.textView.inputDelegate selectionWillChange:self.inputToolbar.contentView.textView];
    [self.inputToolbar.contentView.textView.inputDelegate selectionDidChange:self.inputToolbar.contentView.textView];
    
    NSString * body = self.inputToolbar.contentView.textView.text;
    
    switch(recipientType) {
        case RECIPIENT_TYPE_SMS:
            [self.conversation forwardMessage:self.message withBody:body toSMS:self.textField.text success:success failure:failure];
            break;
        case RECIPIENT_TYPE_EMAIL:
            [self.conversation forwardMessage:self.message withBody:body toEmail:self.textField.text success:success failure:failure];
            break;
        case RECIPIENT_TYPE_SERVICE:
            [self.conversation forwardMessage:self.message withBody:body toService:self.forwardTargetService success:success failure:failure];
            break;
        case RECIPIENT_TYPE_PRINTER:
            [self.conversation forwardMessage:self.message withBody:body toPrinter:selectedPrinter success:success failure:failure];
            break;
        case RECIPIENT_TYPE_HOTSOS:
            [self.conversation forwardMessage:self.message withBody:body toHotsosWithHotsosIssueName:selectedHotsosIssueName room:self.roomNumberTextField.text success:success failure:failure];
            break;
        default:
            SBLogError(@"Something horrible is happening.  They hit forward without selecting a forward type.  Help.");
    }
}

@end
