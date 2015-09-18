# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: http://api.zingle.me/docs/index.html

### Zingle Model Core-Concepts

Model | Description
--- | ---
ZingleSDK | You must instantiate the SDK with proper credentials before you can perform any SDK operations.
ZingleAccount | The Account is the master record for a Zingle Customer.  As the developer you will be granted access to specific Accounts and operate on their behalf.
ZingleService | A valid Account is a container for 1 or more Services.  A Service is a distinct messaging center that contains collections of conversations.
ZinglePlan | Every Service must have an associated Plan.  The plan defines the messaging limitations, features, and cost of the Zingle Service.
ZingleContact | Contacts are individuals that communicate in a 2-way conversation with a Zingle Service.
ZingleLabel | Labels are user-defined colored tags that can be applied to Contacts.  A Service can define 0 or more custom Labels.  You can message all Contacts with a given Label for group messaging capabilities.
ZingleCustomField | Custom Fields are user-defined meta-data that can be applied to Contacts. A Service can define 0 or more Custom Fields.
ZingleChannelType | Channel Types define the mediums which can be used to facilitate communication between the Contact and the Service.  Example Channel Types are: Phone Number, Email Address, and User Defined.
ZingleServiceChannel | A Service Channel is a specific defined medium of communication.  A Service Channel will contain the Channel Type (Phone Number) and the Channel Value (+18585555555).  Service Channels must be unique across the entire Zingle universe.  A Service may contain 1 or more Service Channels of differing Channel Types.
ZingleContactChannel | A Contact Channel is a specific defined medium of communication.  A Contact Channel will contain the Channel Type (Phone Number) and the Channel Value (+18585555555).  Contact Channels must be unique within a specific Service, meaning no 2 Contacts may share the same Channel within a Service.  A Contact may contain 1 or more Contact Channels of differing Channel Types.
ZingleMessage | Messages define the sender, recipient(s), message body, and attachments.  Messages are sent to/from Contacts and Services via their respective Channels: SMS, Email, Web Based IP User Defined channels, etc...

### Instantiating the SDK

**Note:** This page will use the object name "MyZingleApp" for the instance of your ZingleSDK.

```Objective-C
- (void)buildZingleSDK
{
    // Instantiate the master ZingleSDK instance
    ZingleSDK *MyZingleApp = [ZingleSDK SDKWithToken:@"API_TOKEN" andKey:@"API_KEY"];
    
    // Before making any API request via the SDK, you must specify a callback selector to get called 
    // with the result of the request.
    [MyZingleApp setDelegate:self withSelector:@selector(validationResponse:)];

    // This method validates the supplied credentials.
    [MyZingleApp validateAuthentication];
}

- (void)validationResponse:(id)response
{
    NSLog(@"%@", response.message);
    
    if( [response isTypeOfClass:[NSError class]] )
    {
        // An error occurred, authentication validation failed.
    }
}
```


### Accounts

```Objective-C
// Build your account search
ZingleAccountSearch *accountSearch = [MyZingleApp accountSearch];

// Specify search criteria; note stars are used as wild cards.
accountSearch.displayName = @"*Test*";

// Delegate will receive NSError, or NSArray of ZingleAccount objects
[accountSearch setDelegate:self withSelector:@selector(accountSearchResults:)];
[accountSearch search];
```

