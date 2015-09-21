# Object Reference

The following is a reference for the SDK Objects.

## ZingleSDK

Method | Description
--- | ---
```(Objective-C)+ (ZingleSDK *)sharedSDK``` | Returns the singleton ZingleSDK object.
```- (void)setToken:(NSString *)token andKey:(NSString *)key``` | Sets the API credentials on the SDK singleton
```- (BOOL)hasCredentials``` | Returns YES if Token and Key are set on SDK, does not validate credentials.
```- (BOOL)validateCredentials``` | Synchronous API call to validate credentials
```- (void)validateCredentialsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)( NSError *error ) )errorBlock``` | Asynchronous API call to validate credentials.  Completion Block is called on success, otherwise the Error Block.
```- (void)clearCredentials``` | Remove credentials from the SDK object.
```- (ZNGAccountSearch *)accountSearch``` | Builds and returns a ZNGAccountSearch object, to search for Accounts
```- (ZNGTimeZoneSearch *)timeZoneSearch``` | Builds and returns a ZNGTimeZoneSearch object, to list all allowed Time Zones.
```- (ZNGAvailablePhoneNumberSearch *)availablePhoneNumberSearch``` | Builds and returns a ZNGAvailablePhoneNumberSearch object to searh for, and list phone numbers available for provisioning.

## ZNGAccount

Property | Type | Description
--- | --- | ---
displayName | NSString | The name of the Account.

Method | Returns | Description
--- | --- | ---
serviceSearch | ZNGServiceSearch | Builds and returns a new Service Search object
newService | ZNGService | Builds and returns a new empty Service object.
serviceWithID:(NSString *)serviceID | ZNGService | Builds a returns a new Service object, with the ID set as passed.
planSearch | ZNGPlanSearch | Builds and returns a new Plan Search object, to find plans, and prices available to you within an Account.
