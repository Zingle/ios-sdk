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

### Asynchronous and Synchronous

The iOS SDK allows both synchronous and asynchronous operation.  Every method that makes a web service request, will also contain another similar method with two additional parameters for callback blocks on completion and error.

```Objective-C
// Syncronous operation sends, waits, and returns an array of ZNGAccount objects
NSArray *accounts = [(ZNGAccountSearch *)accountSearch search]; 
NSLog(@"Search Complete.  Got Accounts: %@", accounts);

// Asyncronous variation will continue on main thread, and callback on success or error
[(ZNGAccountSearch *)accountSearch searchWithCompletionBlock:^(NSArray *results) {
    NSLog(@"Search Complete.  Got Accounts: %@", results);
} errorBlock:^(NSError *error) {
    NSLog(@"Got Error: %@", error);
}];
```

### Quick Start

The following code snippet will search for an Account you have access to.  Create a new Service, provision a new Phone Number channel, and send a message to a Contact Phone Number.

**Synchronous Example**

```Objective-C
[[ZingleSDK sharedSDK] setToken:@"API_TOKEN" andKey:@"API_KEY"];

BOOL validated = [[ZingleSDK sharedSDK] validateAuthentication];

if( !validated )
{
    NSLog(@"Invalid Credentials");
}
else 
{
    ZNGAccountSearch *accountSearch = [[ZingleSDK sharedSDK] accountSearch];
    NSArray *accounts = [accountSearch search];
    if( [accounts length] == 0 )
    {
        NSLog(@"You don't have access to any accounts.");
    }
    else
    {
        ZNGAccount *firstAccount = [accounts firstObject];
        ZNGPlanSearch *planSearch = [firstAccount planSearch];
        planSearch.code = @"zingle_sandbox";
        NSArray *plans = [planSearch search];
        
        if( [plans length] > 0 )
        {
            ZNGPlan *sandboxPlan = [plans firstObject];
            
            ZNGService *newService = [firstAccount newService];
            newService.displayName = @"My new service";
            newService.plan = sandboxPlan;
            [newService save];
            
            ZNGPhoneNumberSearch *phoneNumberSearch = [newService phoneNumberSearch];
            phoneNumberSearch.country = @"US";
            phoneNumberSearch.areaCode = @"858";
            
            NSArray *availablePhoneNumbers = [phoneNumberSearch search];
            if( [availablePhoneNumbers length] == 0 )
            {
                NSLog(@"No available phone numbers found.");
            }
            else
            {
                ZNGAvailablePhoneNumber *firstAvailablePhoneNumber = [availablePhoneNumbers firstObject];
                ZNGServiceChannel *newServiceChannel = [firstAvailablePhoneNumber newServiceChannel];
                newServiceChannel.is_default = YES;
                [newServiceChannel save];
                
                ZNGMessage *newMessage = [service newMessage];
                ZNGMessageCorrespondent *recipient = [newMessage newCorrespondent];
                
            }
        }
    }
}
```

### Account Search

```Objective-C
// Instantiate the Account Search object from the ZingleSDK instance.
ZingleAccountSearch *accountSearch = [myZingleApp accountSearch];

// Specify search criteria; note stars are used as wild cards.
accountSearch.displayName = @"*Test*";

// Delegate will receive NSError, or NSArray of 0 or more ZingleAccount objects
[accountSearch setDelegate:self withSelector:@selector(accountSearchResults:)];
[accountSearch search];
```

### Service Search

```Objective-C
// Instantiate the Service Search object from a ZingleAccount instance.
ZingleServiceSearch *serviceSearch = [myZingleAccount serviceSearch];

// Specify search criteria
serviceSearch.planId = @"00000000-0000-0000-0000-000000000000";
serviceSearch.serviceDisplayName = @"*Concierge*";
serviceSearch.serviceState = @"CA";

// Delegate will receive NSError, or NSArray of 0 or more ZingleService objects
[serviceSearch setDelegate:self withSelector:@selector(serviceSearchResults:)];
[serviceSearch search];
```

### Available Phone Number Search & Provisioning

One of Zingle's most widely used Channel Types is Phone Number.  As part of the SDK you can search for available Phone Numbers around the world, and assign the Phone Number to a Service Channel.  Contacts can then communicate with your Service via your unique Phone Number. (note: charges may apply)

```Objective-C
- (void)searchForPhoneNumbersInCountry:(NSString *)countryCode 
        withAreaCode:(NSString *)areaCode forService:(ZingleService *)service
{
    // Instantiate the Phone Number Search object from a Zingle Service instance
    ZingleAvailablePhoneNumberSearch *phoneNumberSearch = [service availablePhoneNumberSearch];
    
    // Specify search criteria
    phoneNumberSearch.country = countryCode;
    phoneNumberSearch.areaCode = areaCode;
    
    // Delegate will receive NSError, or NSArray of 0 or more ZingleAvailablePhoneNumber objects
    [phoneNumberSearch setDelegate:self withSelector:@selector(phoneNumberSearchResults:)];
    [phoneNumberSearch search];
}

- (void)phoneNumberSearchResults:(id)result
{
    if( [result isTypeOfClass:[NSError class]] )
    {
        // An error occurred
    }
    else 
    {
        NSArray *availablePhoneNumbers = (NSArray *)result;
        
        if( [availablePhoneNumbers count] > 0 )
        {
            // Grab the first available phone number from the array
            ZingleAvailablePhoneNumber *firstPhoneNumber = [availablePhoneNumbers firstObject];
            NSLog(@"First Available Phone Number: %@", firstPhoneNUmber);
            
            // We build a new Channel from the phone number which will associate to the Service
            // that the ZingleAvailablePhoneNumberSearch was instantiated from.
            ZingleServiceChannel *newServiceChannel = [firstPhoneNumber newServiceChannel];
            [newServiceChannel setDelegate:self withSelector:@selector(phoneNumberProvisionResult:)];
            
            // WARNING: Saving the new Service Channel will provision the phone number, and 
            // associate the Channel to the Service that the ZingleAvailablePhoneNumberSearch 
            // was instantiated from.  Charges may apply.
            [newServiceChannel save];
        }
    }
}
```

**Asynchronous Example**

### Contact Search

```Objective-C
// Instantiate the Contact Search object from a ZingleService instance
ZingleServiceContactSearch *contactSearch = [myHotelConciergeService contactSearch];

// Specify your search criteria; stars act as wild-cards
contactSearch.firstName = @"Bob*";

// Delegate will receive NSError, or NSArray of 0 or more ZingleContact objects
[contactSearch setDelegate:self withSelector:@selector(contactSearchResults:)];
[contactSearch search];
```

### Labels

#### Search Labels on a Service

```Objective-C
// Instantiate the Label Search object from a ZingleService instance
ZingleServiceLabelSearch *labelSearch = [myHotelConciergeService labelSearch];

// Delegate will receive NSError, or NSArray of 0 or more ZingleLabel objects
[labelSearch setDelegate:self withSelector:@selector(labelSearchResults:)];
[labelSearch search];
```

#### Create a new Label for a Service

```Objective-C
// Create a new Label object from a ZingleService instance
ZingleLabel *myNewLabel = [myHotelConciergeService newLabel];

// Set your new label properties
myNewLabel.displayName = @"VIP";
myNewLabel.backgroundColor = [UIColor greenColor];
myNewLabel.textColor = [UIColor whiteColor];

// Delegate will receive NSError, or a reference back to your newly created Label 
[newLabel setDelegate:self withSelector:@selector(labelCreationResult:)];

// Save the Label
[newLabel save];
```
