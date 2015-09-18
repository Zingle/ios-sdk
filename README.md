# Zingle iOS SDK

## Overview

Zingle provides a omni-channel communications platform to business all over the world. The Zingle SDK aims to provide application developers an easy-to-use layer on top of the Zingle API.

### Instantiating the SDK

```Objective-C
// Build the master ZingleSDK instance
ZingleSDK *Zingle = [Zingle SDKWithToken:@"API_TOKEN" andKey:@"API_KEY"];

// Before making a service request, you must specify a callback selector to get called with the result of the request.
[Zingle setDelegate:self withSelector:@selector(validationResponse:)];

// Validate the supplied authentication credentials.This step is not required to begin making SDK calls, but should be your first step to validate you have a positive connection to the Zingle API when you start development.
[Zingle validateAuthentication];
```

```Objective-C
- (void)validationResponse:(id)response
{
    NSLog(@"%@", response.message);
    
    if( [response isTypeOfClass:[NSError class]] )
    {
        // An error occurred    
    }
}
```
