# ZingleSDK

Method | Description
--- | ---
```+ (ZingleSDK *)sharedSDK``` | Returns the singleton ZingleSDK object.
```- (void)setToken:(NSString *)token andKey:(NSString *)key``` | Sets the API credentials on the SDK singleton
```- (BOOL)hasCredentials``` | Returns YES if Token and Key are set on SDK, does not validate credentials.
```- (BOOL)validateCredentials``` | Synchronous API call to validate credentials
```- (void)validateCredentialsWithCompletionBlock:( void (^)(void) )completionBlock errorBlock:( void (^)( NSError *error ) )errorBlock``` | Asynchronous API call to validate credentials.  Completion Block is called on success, otherwise the Error Block.



# ZNGAccount

Property | Type | Description
--- | --- | ---
displayName | NSString | The name of the Account.

Method | Returns | Description
--- | --- | ---
serviceSearch | ZNGServiceSearch | Builds and returns a new Service Search object
newService | ZNGService | Builds and returns a new empty Service object.
serviceWithID:(NSString *)serviceID | ZNGService | Builds a returns a new Service object, with the ID set as passed.
planSearch | ZNGPlanSearch | Builds and returns a new Plan Search object
