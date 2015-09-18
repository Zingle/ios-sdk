# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: http://api.zingle.me/docs/index.html

### Zingle Models Overview

Model | Description
--- | ---
ZingleSDK | This is the master SDK Class.  You must instantiate the SDK before you can perform SDK operations.
ZingleAccount | After authenticating, you are granted specific privileges to Accounts and Services within the Zingle platform.  It is often easiest to think of an Account as specific Business Location, where the Services within that account would be seperate distinct message centers for that Account.
ZingleService | An Account is a container for 1 or more Service subscriptions.  Most objects within the SDK are required to know which Service they belong to.
ZingleContact | A Contact is the 
ZingleLabel | Labels are custom colored tags that can be applied to Contacts.  A Service can contain 0 or more Labels.

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

