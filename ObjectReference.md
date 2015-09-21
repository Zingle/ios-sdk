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

Property | Type
--- | --- | ---
```displayName``` | NSString

Method |  Description
--- | ---
```- (ZNGServiceSearch *)serviceSearch``` | Builds and returns a new Service Search object
```- (ZNGService *)newService``` | Builds and returns a new empty Service object. (unsaved)
```- (ZNGService *)serviceWithID:(NSString *)serviceID``` |  Builds a returns a new Service object, with the ID set. (unsaved)
```- (ZNGPlanSearch *)planSearch``` | Builds and returns a new Plan Search object, to find plans, and prices available to you within an Account.

## ZNGService

Property | Type
--- | --- 
```account``` | ZNGAccount
```displayName``` | NSString
```timeZone``` | NSString
```plan``` | ZNGPlan
```address``` | ZNGAddress
```channels``` | NSArray
```channelTypes``` | NSArray

Method | Description
--- | ---
```- (void)cancelSubscriptionNow``` |
```- (ZNGContact *)newContact``` |
```- (ZNGContact *)contactWithID:(NSString *)contactID``` |
```- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass``` |
```- (NSMutableArray *)channelTypesWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName``` |
```- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass``` |
```- (ZNGChannelType *)firstChannelTypeWithClass:(NSString *)typeClass andDisplayName:(NSString *)displayName``` |
```- (ZNGChannelType *)channelTypeWithID:(NSString *)channelTypeID``` |
```- (ZNGLabel *)newLabel``` |
```- (ZNGCustomField *)newCustomField``` |
```- (ZNGServiceSettingsSearch *)serviceSettingsSearch``` |
```- (ZNGContactSearch *)contactSearch``` |
```- (ZNGServiceChannel *)newChannel``` |
```- (ZNGLabelSearch *)labelSearch``` |
```- (ZNGCustomFieldSearch *)customFieldSearch``` |
```- (ZNGMessageSearch *)messageSearch``` |
```- (ZNGAutomationSearch *)automationSearch``` |
```- (ZNGWebServiceLogSearch *)webServiceLogSearch``` |
```- (ZNGAvailablePhoneNumberSearch *)availablePhoneNumberSearch``` |

## ZNGAvailablePhoneNumber

Property | Type
--- | ---
```phoneNumber``` | NSString
```formattedPhoneNumber``` | NSString
```country``` | NSString

Method | Description
--- | ---
```- (ZNGServiceChannel *)newServiceChannel``` | 
```- (ZNGServiceChannel *)newServiceChannelFor:(ZNGService *)service``` | 
```- (ZNGServiceChannel *)provisionAsServiceDefault:(BOOL)asDefault``` | 
```- (ZNGServiceChannel *)provisionForService:(ZNGService *)service asServiceDefault:(BOOL)asDefault``` | 

## ZNGAddress

Property | Type
--- | ---
```address``` | NSString
```city``` | NSString
```country``` | NSString
```postalCode``` | NSString
```state``` | NSString

## ZNGLabel

Property | Type
--- | ---
```service``` | ZNGService
```displayName``` | NSString
```isAutomatic``` | BOOL
```isGlobal``` | BOOL
```backgroundColor``` | UIColor
```textColor``` | UIColor

Method | Description
--- | ---
```- (void)save``` | 
```- (void)saveWithCompletionBlock:(void (^) (void))completionBlock errorBlock:(void (^) (NSError *error))errorBlock``` | 
