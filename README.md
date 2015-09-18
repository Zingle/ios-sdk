# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide application developers an easy-to-use layer on top of the Zingle API.

### Instantiating the SDK

```Objective-C
- (void)buildZingleSDK
{
    // Instantiate the master ZingleSDK instance
    ZingleSDK *Zingle = [Zingle SDKWithToken:@"API_TOKEN" andKey:@"API_KEY"];
    
    // Before making any API request via the SDK, you must specify a callback selector to get called 
    // with the result of the request.
    [Zingle setDelegate:self withSelector:@selector(validationResponse:)];

    // This method validates the supplied credentials.
    [Zingle validateAuthentication];
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
// Instantiate the SDK
ZingleSDK *Zingle = [Zingle SDKWithToken:@"API_TOKEN" andKey:@"API_KEY"];

// Build your account search
ZingleAccountSearch *accountSearch = [Zingle accountSearch];
[accountSearch setDelegate:self withSelector:@selector(accountSearchResults:)];
[accountSearch search];
```

