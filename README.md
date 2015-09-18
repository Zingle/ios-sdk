# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: http://api.zingle.me/docs/index.html

### Zingle Model Core-Concepts

Model | Description
--- | ---
ZingleSDK | This is the master class.  You must instantiate the SDK before you can perform any SDK operations.
ZingleAccount | After authenticating, you are granted specific privileges to Accounts and Services within the Zingle platform.  It is often easiest to think of an Account as specific Business Location, where the Services within that account are seperate distinct messaging centers.
ZingleService | An Account is a container for 1 or more Services.  A Service is a distinct messaging center that contains collections of conversations.  NOTE: Most objects within the Zingle SDK are required to know which Service they belong to.
ZinglePlan | Every Service must have an associated Plan.  The plan defines the messaging limitations, features, and cost of the Zingle Service.
ZingleContact | Contacts are people that are communicating with a Zingle Service.
ZingleLabel | Labels are user-defined colored tags that can be applied to Contacts.  A Service can define 0 or more custom Labels.
ZingleCustomField | Custom Fields are user-defined meta-data that can be applied to Contacts. A Service can define 0 or more Custom Fields.
ZingleChannelType | Channels are mediums which are used to facilitate communication between the Contact and the Service.  Example Channel Types are: Phone Number, Email Address, User Defined.  For IP based communication, you can specify custom Channel Types which you can give a custom friendly name.
ZingleServiceChannel | A Service contains 1 or more Service Channels, which are specific defined mediums of communication.  A Service Channel will contain the Channel Type (Phone Number) and the Channel Value (+18585555555).  Service Channels must be unique across the entire Zingle universe, and they may never overlap.
ZingleContactChannel | A Contact contains 1 or more Contact Channels.  Like Service Channels, they define the medium at which communication will be facilitated.  A Contact Channel also contains the Channel Type and Channel Value.
ZingleMessage | The message defines the sender, recipient, message body, and any attachments.

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

