# Zingle iOS SDK

## Overview

Zingle is the global leader in omni-channel communication management.  Our award winning platform is used by businesses all over the world to enhance the consumer to business conversation experience. The Zingle SDK aims to provide application developers an easy-to-use layer on top of the Zingle API.

### Instantiating the SDK

```Objective-C
// Instantiate the master ZingleSDK instance
ZingleSDK *Zingle = [Zingle SDKWithToken:@"API_TOKEN" andKey:@"API_KEY"];

// Before making a service request, you must specify a callback selector to get called 
// with the result of the request.
[Zingle setDelegate:self withSelector:@selector(validationResponse:)];

// Validate the supplied authentication credentials.This step is not required to begin 
// making SDK calls, but should be your first step to validate you have a positive 
// connection to the Zingle API when you start development.
[Zingle validateAuthentication];
```

**Delegate**

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

### Asyncronous Model

The SDK provides a simple to use layer on top of the Zingle API.  Models have many methods on them that require a web service call to the internet.  You will be required to specify a callback method before you make these calls if you want to be notified of the results of the call.

**Example**

```Objective-C

```

