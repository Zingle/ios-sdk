
### Synchronous Quick Start

```Objective-C

@implementation ViewController

- (void)zingleSynchronousTest
{
    [[ZingleSDK sharedSDK] setToken:@"API_TOKEN" andKey:@"API_KEY"];

    // Ensure your API credential are valid
    if( ![[ZingleSDK sharedSDK] validateCredentials] )
    {
        NSLog(@"Invalid Credentials");
        return;
    }
    
    // Searches for all Accounts your credentials grant access to
    ZNGAccountSearch *accountSearch = [[ZingleSDK sharedSDK] accountSearch];
    NSArray *accounts = [accountSearch search];
    if( [accounts length] == 0 )
    {
        NSLog(@"You don't have access to any accounts.");
        return;
    }
    
    // Grab the first account returned - change this if you want to use a specific account
    ZNGAccount *firstAccount = [accounts firstObject];
    
    // Search for the "zingle_sandbox" plan, which grants special privileges for development testing.
    ZNGPlanSearch *planSearch = [firstAccount planSearch];
    planSearch.code = @"zingle_sandbox";
    NSArray *plans = [planSearch search];
    ZNGPlan *sandboxPlan = [plans firstObject];
    
    // Create a new Service using the sandbox plan
    ZNGService *newService = [firstAccount newService]; 
    newService.plan = sandboxPlan;
    
    // Change this name to whatever you'd like
    newService.displayName = @"My new service";
    newService.address.address = @"1234 Jovin Street";
    newService.address.city = @"Carlsbad";
    newService.address.state = @"CA";
    newService.address.postalCode = @"92101";
    newService.address.country = @"US";
    
    // Once the Service is saved, you should be able to login
    // to https://dashboard.zingle.me and see your new Service
    [newService save];
    
    // Create a new Custom Field available to your Service.
    ZNGCustomField *membershipNumber = [newService newCustomField];
    membershipNumber.displayName = @"Membership Number";
    
    // Once the Custom Field is saved, the Custom Field Value can be
    // set on any Contact.
    [membershipNumber save];
    
    // Create a new Label available to your Service.
    ZNGLabel *vipLabel = [newService newLabel];
    vipLabel.backgroundColor = [UIColor yellowColor];
    vipLabel.foregroundColor = [UIColor blueColor];
    vipLabel.displayName = @"VIP";
    
    // Once the Label is saved, it can be attached to any Contact
    [vipLabel save];
    
    // Search for available SMS-capable phone numbers
    ZNGPhoneNumberSearch *phoneNumberSearch = [newService phoneNumberSearch];
    phoneNumberSearch.country = @"US";
    phoneNumberSearch.areaCode = @"858";
    
    NSArray *availablePhoneNumbers = [phoneNumberSearch search];
    if( [availablePhoneNumbers length] == 0 )
    {
        NSLog(@"No available phone numbers found.");
        return;
    }
    
    // Grab the first available phone number in the array, and build a new Service Channel
    ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
    ZNGServiceChannel *newServiceChannel = [firstAvailablePhoneNumber newServiceChannel];
    newServiceChannel.is_default = YES;
    
    // WARNING: Saving a new Phone Number Service Channel provisions the phone number 
    // immediately.  For sandbox accounts, the Phone Number will only survive for 30 days
    // or 100 messages, and then be released.  (which ever comes first).  They are to be
    // used for testing only.  In a Service with a non-sandbox Plan, Phone Numbers may
    // trigger a increase in cost.  Please see your account for details.
    [newServiceChannel save];
    
    // Create a new contact, and set some Custom Field Values
    ZNGContact *contact = [newService newContact];
    [contact setValue:@"David" forCustomField:@"First Name"]; // Enter your first name here
    [contact setValue:@"Peace" forCustomField:@"Last Name"];  // Enter your last name here
    [contact setValue:@"123-467-98" forCustomField:@"Membership Number"];
    [contact save];
    
    // Apply your new VIP Label to the Contact
    [contact applyLabel:vipLabel];
    
    // Create a new Phone Number Contact Channel
    // Use your own SMS-capable cell phone number for testing
    ZNGContactChannel *contactChannel = [contact newContactChannel];
    contactChannel.channelType = [newService channelTypeWithClass:@"PhoneNumber"];
    contactChannel.channelValue = @"+18585555555";
    [contactChannel save];
    
    // WARNING: Sending this message will actually send a real SMS from the Service Channel
    // Phone Number, to the Contact Channel Phone Number.  Please ensure your are
    // operating responsibly.
    ZNGMessage *newMessage = [newService newMessage];
    [newMessage addRecipient:contact];
    newMessage.body = @"Dear {FIRST_NAME}, welcome to Zingle - you have successfully set up, and messaged from a New Service. Your membership # is: {MEMBERSHIP_NUMBER}.";
    [newMessage send];
}

@end
```
