# Zingle iOS SDK

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: http://api.zingle.me/docs/index.html

### Zingle Object Model

Model | Description
--- | ---
ZingleSDK | A singleton master object that holds the credentials, stateful information, and the distribution of notifications in the ZingleSDK.
ZNGAccount | An Account is the master record for a Business that uses Zingle.  As the developer you will be granted access to specific Accounts, and be provided the ability to perform operations on their behalf.  An Account is a container for one or more Services.
ZNGService | A Service is a distinct messaging center that contains collections of conversations with Contacts. 
ZNGPlan | Every Service must have an associated Plan.  The plan defines the messaging limitations, features, and cost of the Zingle Service.
ZNGContact | Contacts are customers to the Business. They are individuals that communicate in a two-way conversation with a Zingle Service.
ZNGAvailablePhoneNumber | As part of the Zingle platform, you are able to search for, and provision new SMS-capable Phone Numbers.  These phone numbers will become an additional Channel on which Contacts can communicate to your Service.
ZNGLabel | Labels are customizeable colored tags that can be applied to Contacts. Services may message all Contacts with a given Label for group messaging capabilities.
ZNGCustomField | Custom Fields provide the ability to add variable meta data to Contacts. Custom Fields are useful for maintaining relevant stateful information about your Contacts.
ZNGCustomFieldOption | Custom Fields may be either simple types (like a string), or be an option list.  Custom Field Options are the invididual values within an option list.
ZNGCustomFieldValue | When updating Custom Field data on a Contact, you are actually updating a Custom Field Value object.  This entity maps a Custom Field to the value on the Contact.
ZNGChannelType | Channel Types are the medium that facilitate communication between the Contact and the Service.  Example Channel Types are: Phone Number, Email Address, and User Defined.
ZNGServiceChannel | A Service Channel is the way Contacts can communicate with a Service.  A Service Channel might have a Channel Type of Phone Number, with a Channel Value of +18585555555.  Service Channels **must** be unique across the entire Zingle platform.  A Service may contain multiple Service Channels of differing Channel Types.
ZNGContactChannel | A Contact Channel is the way Services can communicate with a Contact.  A Contact Channel might have a Channel Type of Phone Number, with a Channel Value of +18585555555.  Contact Channels **must** be unique within a Zingle Service.  A Contact may contain multiple Contact Channels of differing Channel Types.
ZNGMessage | Messages define the sender, recipient(s), message body, and attachments.  Messages are sent to/from Contacts, Services and Labels via Channels.
ZNGMessageCorrespondent | Message Correspondents are the abstract representation of either the Sender or Recipient on a Message.
ZNGMessageAttachment | Message Attachments provide the ability to add binary data, such as images, to messages.
ZNGAutomation | Automations perform triggered tasks, based on conditions, within the Zingle platform without any direct user interaction.  Tasks include messaging contacts, applying labels, applying custom fields, printing to Zingle Printers, and much more.

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
