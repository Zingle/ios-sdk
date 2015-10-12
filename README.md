# Zingle iOS SDK

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/

### Zingle Object Model

Model | Description
--- | ---
ZingleSDK | A singleton master object that holds the credentials, stateful information, and the distribution of notifications in the ZingleSDK.
ZNGAccount | [See Zingle Resource Overview - Account](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#account)
ZNGService | [See Zingle Resource Overview - Service](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#service)
ZNGPlan | [See Zingle Resource Overview - Plan](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#plan)
ZNGContact | [See Zingle Resource Overview - Contact](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#contact)
ZNGAvailablePhoneNumber | [See Zingle Resource Overview - Available Phone Number](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#available-phone-number)
ZNGLabel | [See Zingle Resource Overview - Label](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#label)
ZNGCustomField | [See Zingle Resource Overview - Custom Field](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field)
ZNGCustomFieldOption | [See Zingle Resource Overview Custom Field Option](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field-option)
ZNGCustomFieldValue | [See Zingle Resource Overview - Custom Field Value](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field-value)
ZNGChannelType | [See Zingle Resource Overview - Channel Type](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#channel-type)
ZNGServiceChannel | [See Zingle Resource Overview  - Service Channel](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#service-channel)
ZNGContactChannel | [See Zingle Resource Overview - Contact Channel](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#contact-channel)
ZNGMessageCorrespondent | Message Correspondents are the abstract representation of either the Sender or Recipient on a Message.
ZNGMessageAttachment | Message Attachments provide the ability to add binary data, such as images, to messages.
ZNGConversation | Model responsible for maintaining the state of a conversation between a Contact and a Service.
ZNGConversationViewController | UI that manages the conversation between a Contact and a Service.
ZNGAutomation | [See Zingle Resource Overview - Automation](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#automation)

To view the Quick Start using synchronous examples, please see: [SynchronousQuickStart.md](SynchronousQuickStart.md)

### Asynchronous Quick Start

```Objective-C
@interface ZingleAsyncQuickStart ()

@property (nonatomic) BOOL authenticated;
@property (nonatomic, retain) ZNGAccount *firstAccount;
@property (nonatomic, retain) ZNGService *myNewService;
@property (nonatomic, retain) ZNGContact *myNewContact;
@property (nonatomic, retain) NSArray *contactCustomFields;
@property (nonatomic, retain) ZNGConversation *conversation;
@property (nonatomic, retain) ZNGConversationViewController *conversationViewController;
@end

@implementation ZingleAsyncQuickStart

- (void)startAsynchronousTest
{
    [[ZingleSDK sharedSDK] setToken:@"" andKey:@""];
    
    // Uncomment the following line to see detailed logging on the underlying API
    // [[ZingleSDK sharedSDK] setGlobalLogLevel:ZINGLE_LOG_LEVEL_VERBOSE];

    // Ensure your API credential are valid
    [[ZingleSDK sharedSDK] validateCredentialsWithCompletionBlock:^{
        self.authenticated = YES;
        [self getAllMyAccounts];
    } errorBlock:^(NSError *error) {
        self.authenticated = NO;
        NSLog(@"Authentication Failed: %@", error);
    }];
}


- (void)getAllMyAccounts
{
    // Searches for all Accounts your credentials grant access to
    [[ZingleSDK sharedSDK] allAccountsWithCompletionBlock:^(NSArray *accounts) {
        
        if( [accounts count] == 0 ) {
            NSLog(@"You don't have access to any accounts.");
            return;
        }
        
        // Grab the first account returned - change this if you want to use a different account
        self.firstAccount = [accounts firstObject];
        
        [self findSandboxPlan];
    } errorBlock:^(NSError *error) {
        NSLog( @"Getting Accounts Failed: %@", error );
    }];
}

- (void)findSandboxPlan
{
    // Search for the "sandbox" plan, which grants special privileges for development testing.
    [self.firstAccount findPlanByCode:@"sandbox" withCompletionBlock:^(ZNGPlan *plan){
        [self createServiceWithPlan:plan];
    } errorBlock:^(NSError *error) {
        NSLog( @"Finding Sandbox Plan Failed: %@", error );
    }];
}

- (void)createServiceWithPlan:(ZNGPlan *)sandboxPlan
{
    // Create a new Service using the sandbox plan
    self.myNewService                    = [self.firstAccount newService];
    self.myNewService.plan               = sandboxPlan;
    self.myNewService.timeZone           = @"America/New_York";
    self.myNewService.displayName        = @"Super AWesome SVCS2345";
    self.myNewService.address.address    = @"1234 Jovin Street";
    self.myNewService.address.city       = @"Carlsbad";
    self.myNewService.address.state      = @"CA";
    self.myNewService.address.postalCode = @"92101";
    self.myNewService.address.country    = @"US";
    
    // Once the Service is saved, you should be able to login
    // to https://dashboard.zingle.me and see your new Service
    [self.myNewService saveWithCompletionBlock:^{
        [self findPhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"Creating New Service Failed: %@", error );
    }];
}

- (void)findPhoneNumber
{
    // Search for available SMS-capable phone numbers
    ZNGAvailablePhoneNumberSearch *phoneNumberSearch = [[ZNGAvailablePhoneNumberSearch alloc] init];
    phoneNumberSearch.country = @"US";
    phoneNumberSearch.areaCode = @"858";
    
    [phoneNumberSearch searchWithCompletionBlock:^(NSArray *availablePhoneNumbers) {
        if( [availablePhoneNumbers count] == 0 ) {
            NSLog(@"No available phone numbers found with Country=%@ and areaCode=%@.",
                  phoneNumberSearch.country, phoneNumberSearch.areaCode);
            return;
        }
        
        // Grab the first available phone number in the array, and build a new Service Channel
        ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
        
        [self provisionPhoneNumber:firstAvailablePhoneNumber];
    } errorBlock:^(NSError *error) {
        NSLog( @"Finding Phone Numbers Failed: %@", error );
    }];
}

- (void)provisionPhoneNumber:(ZNGAvailablePhoneNumber *)availablePhoneNumber
{
    [self.myNewService provisionPhoneNumber:availablePhoneNumber asDefaultChannel:YES withCompletionBlock:^(ZNGServiceChannel *newServiceChannel) {
        
        [self populateContactCustomFieldsOnService];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error Provisioning Phone Number: %@", error);
    }];
}

- (void)populateContactCustomFieldsOnService
{
    [self.myNewService populateAllContactCustomFieldsWithCompletionBlock:^{
        
        [self saveNewContact];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error populating custom fields on Service: %@", error);
    }];
}

- (void)saveNewContact
{
    self.myNewContact = [self.myNewService newContact];
    
    [self.myNewContact setCustomFieldValueTo:@"David" forCustomFieldWithName:@"First Name"];
    [self.myNewContact setCustomFieldValueTo:@"Peace" forCustomFieldWithName:@"Last Name"];
    
    [self.myNewContact saveWithCompletionBlock:^{
        
        NSLog(@"New Contact: %@", self.myNewContact);
        [self sendMessage];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error saving new contact: %@", error);
    }];
}

- (void)sendMessage
{
    
}

- (void)getConversation
{
     self.conversation = [[ZNGConversation alloc] initWithService:self.myNewService];
    [self.conversation setContact:myNewContact];
    
    self.conversationViewController = [[ZNGConversationViewController alloc] initWithConversation:self.conversation];
    
    self.conversationViewController.horizontalMargin = 5;
    self.conversationViewController.outboundBackgroundColor = [UIColor greenColor];
    self.conversationViewController.inboundBackgroundColor = [UIColor purpleColor];
    self.conversationViewController.arrowPosition = ZINGLE_ARROW_POSITION_BOTTOM;
    
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}

@end
```
