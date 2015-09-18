# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide application developers an easy-to-use layer on top of the Zingle API.

Throughout the documentation on this page we will use the object name "MyZingleApp" for the instance of your ZingleSDK.

### Instantiating the SDK

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

Authenticating with the API will grant you privileges to Accounts and Services within the Zingle platform.

```Objective-C
// Build your account search
ZingleAccountSearch *accountSearch = [MyZingleApp accountSearch];

// Specify search criteria; note stars are used as wild cards.
accountSearch.displayName = @"*Test*";

// Delegate will receive NSError, or NSArray of ZingleAccount objects
[accountSearch setDelegate:self withSelector:@selector(accountSearchResults:)];
[accountSearch search];
```

