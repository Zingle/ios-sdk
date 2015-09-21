# Zingle iOS SDK

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/

### Zingle Object Model

Model | Description
--- | ---
ZingleSDK | A singleton master object that holds the credentials, stateful information, and the distribution of notifications in the ZingleSDK.
ZNGAccount | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGService | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGPlan | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGContact | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGAvailablePhoneNumber | As part of the Zingle platform, you are able to search for, and provision new SMS-capable Phone Numbers.  These phone numbers will become an additional Channel on which Contacts can communicate to your Service.
ZNGLabel | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGCustomField | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGCustomFieldOption | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGCustomFieldValue | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGChannelType | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGServiceChannel | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGContactChannel | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)
ZNGMessageCorrespondent | Message Correspondents are the abstract representation of either the Sender or Recipient on a Message.
ZNGMessageAttachment | Message Attachments provide the ability to add binary data, such as images, to messages.
ZNGAutomation | [See Zingle Resource Overview](https://github.com/Zingle/rest-api/blob/master/resource_overview.md)

To view the Quick Start using synchronous examples, please see: [SynchronousQuickStart.md](SynchronousQuickStart.md)

### Asynchronous Quick Start

```Objective-C

@interface ZingleAsynchronousTest ()

@property (nonatomic) BOOL authenticated;
@property (nonatomic, retain) NSArray *accounts, *services, *plans;
@property (nonatomic, retain) ZNGAccount *firstAccount;
@property (nonatomic, retain) ZNGService *myNewService;
@property (nonatomic, retain) ZNGCustomField *membershipNumberField;
@property (nonatomic, retain) ZNGLabel *vipLabel;
@property (nonatomic, retain) ZNGContact *myNewContact;

@end

@implementation ZingleAsynchronousTest

- (void)startAsynchronousTest
{
    [[ZingleSDK sharedSDK] setToken:@"API_TOKEN" andKey:@"API_KEY"];

    // Ensure your API credential are valid
    [[ZingleSDK sharedSDK] validateCredentialsWithCompletionBlock:^{
        self.authenticated = YES;
        [self getAllMyAccounts];
    } errorBlock:^(NSError *error) {
        NSLog(@"Invalid Credentials");
    }];
}

- (void)getAllMyAccounts
{
    // Searches for all Accounts your credentials grant access to
    [[ZingleSDK sharedSDK] accountSearchWithCompletionBlock:^(NSArray *accounts) {
        self.accounts = accounts;
        
        if( [accounts length] == 0 ) {
            NSLog(@"You don't have access to any accounts.");
            return;
        }
        
        // Grab the first account returned - change this if you want to use a different account
        self.firstAccount = [accounts firstObject];
        
        [self findSandboxPlan];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)findSandboxPlan
{
    // Search for the "zingle_sandbox" plan, which grants special privileges for development testing.
    ZNGPlanSearch *planSearch = [self.firstAccount planSearch];
    planSearch.code = @"zingle_sandbox";
    
    [planSearch searchWithCompletionBlock:^(NSArray *plans){
        ZNGPlan *sandboxPlan = [plans firstObject];
        [self createServiceWithPlan:sandboxPlan];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)createServiceWithPlan:(ZNGPlan *plan)sandboxPlan
{
    // Create a new Service using the sandbox plan
    self.myNewService                    = [self.firstAccount newService]; 
    self.myNewService.plan               = sandboxPlan;
    self.myNewService.displayName        = @"My new service";
    self.myNewService.address.address    = @"1234 Jovin Street";
    self.myNewService.address.city       = @"Carlsbad";
    self.myNewService.address.state      = @"CA";
    self.myNewService.address.postalCode = @"92101";
    self.myNewService.address.country    = @"US";
    
    // Once the Service is saved, you should be able to login
    // to https://dashboard.zingle.me and see your new Service
    [self.myNewService saveWithCompletionBlock:^{
        [self findServicePhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)findServicePhoneNumber
{
    // Search for available SMS-capable phone numbers
    ZNGPhoneNumberSearch *phoneNumberSearch = [self.myNewService phoneNumberSearch];
    phoneNumberSearch.country = @"US";
    phoneNumberSearch.areaCode = @"858";
    
    [phoneNumberSearch searchWithCompletionBlock:^(NSArray *availablePhoneNumbers) {
        if( [availablePhoneNumbers length] == 0 )
        {
            NSLog(@"No available phone numbers found with Country=%@ and areaCode=%@.", 
                        phoneNumberSearch.country, phoneNumberSearch.areaCode);
            return;
        }
        
        // Grab the first available phone number in the array, and build a new Service Channel
        ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
        
        [self createNewServiceChannelWithPhoneNumber:firstAvailablePhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)createNewServiceChannelWithPhoneNumber:(ZNGAvailablePhoneNumber *)firstAvailablePhoneNumber
{
    // Since ZNGPhoneNumberSearch was spawned from the ZNGService model, the
    // ZNGAvailablePhoneNumber object already has a reference to the Service it will 
    // be associated with.
    ZNGServiceChannel *newServiceChannel = [firstAvailablePhoneNumber newServiceChannel];
    newServiceChannel.is_default = YES;
    
    // WARNING: Saving a new Phone Number Service Channel provisions that phone number 
    // immediately.  For sandbox accounts the Phone Number will only survive for 30 days
    // or 100 messages, and then be released; which ever comes first.  They are to be
    // used for testing only.  In a Service with a non-sandbox Plan, Phone Numbers may
    // trigger a increase in cost.  Please see your account for details.
    [newServiceChannel saveWithCompletionBlock:^{
        [self phoneNumberProvisioned];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)phoneNumberProvisioned
{
    // Create a new Custom Field available to your Service.
    self.membershipNumberField             = [self.myNewService newCustomField];
    self.membershipNumberField.displayName = @"Membership Number";
    
    // Once the Custom Field is saved, the Custom Field Value can be
    // set on any Contact.
    [self.membershipNumberField saveWithCompletionBlock:^{
        [self customFieldSaved];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)customFieldSaved
{
    // Create a new Label available to your Service.
    self.vipLabel                 = [self.newService newLabel];
    self.vipLabel.backgroundColor = [UIColor yellowColor];
    self.vipLabel.foregroundColor = [UIColor blueColor];
    self.vipLabel.displayName     = @"VIP";
    
    // Once the Label is saved, it can be attached to any Contact
    [self.vipLabel saveWithCompletionBlock:^{
        [self labelSaved];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)labelSaved
{
    // Create a new contact, and set some Custom Field Values
    self.myNewContact = [newService newContact];
    [self.myNewContact saveWithCompletionBlock:^{
        
        [self.myNewContact setValue:@"David" forCustomField:@"First Name"];
        [self.myNewContact setValue:@"Peace" forCustomField:@"Last Name"];
        [self.myNewContact setValue:@"123-467-98" forCustomField:self.membershipNumberField];
        
        // Apply your new VIP Label to the Contact
        [self.myNewContact applyLabel:vipLabel];
    
        [self newContactCreated];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)newContactCreated
{
    // Create a new Phone Number Contact Channel
    // Use your own SMS-capable cell phone number for testing
    ZNGContactChannel *contactChannel = [contact newContactChannel];
    contactChannel.channelType = [self.myNewService channelTypeWithClass:@"PhoneNumber"];
    contactChannel.channelValue = @"+18585555555";
    [contactChannel saveWithCompletionBlock:^{
        [self sendMessage];
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}

- (void)sendMessage
{
    // WARNING: Sending this message will actually send a real SMS from the Service Channel
    // Phone Number, to the Contact Channel Phone Number.  Ensure you have permission to 
    // send a text message to the number you supplied.
    ZNGMessage *newMessage = [self.myNewService newMessage];
    [newMessage addRecipient:self.myNewContact];
    newMessage.body = @"Dear {FIRST_NAME}, welcome to Zingle - you have successfully set up, and messaged from a New Service. Your membership # is: {MEMBERSHIP_NUMBER}.";
    [newMessage sendWithCompletionBlock:^{
        NSLog( @"Ayncronous Test Completed Successfully" );
    } errorBlock:^(NSError *error) {
        NSLog( @"An error occurred: %@", error );
    }];
}
@end
```
