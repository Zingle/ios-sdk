# Zingle iOS SDK
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ZingleSDK.svg)](https://img.shields.io/cocoapods/v/ZingleSDK.svg)
[![Platform](https://img.shields.io/cocoapods/p/ZingleSDK.svg?style=flat)](http://cocoadocs.org/docsets/ZingleSDK)
[![Twitter](https://img.shields.io/badge/twitter-@zingleme-blue.svg?style=flat)](https://twitter.com/zingleme)

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/

## Contact vs. Account class sessions

### Contact session

A contact session represents someone such as a hotel guest.  This session is used by user of a third party application that uses the Zingle API to communicate with a service, such as a hotel front desk, on behalf of the user.

> All usage examples in this README will address contact class usage.

### Account session

An account session represents a Zingle customer using the API to communicate with their own guests or customers.

For further information regarding account class usage, see [Using the SDK as an Account Class User](Documentation/AccountUsage.md).

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like the ZingleSDK in your projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

#### Podfile

To integrate the ZingleSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'ZingleSDK'
```

Then, run the following command:

```bash
$ pod install
```

Import the SDK header file where needed:
```objective-c
#import <ZingleSDK/ZingleSDK.h>
```

## Session creation

Several pieces of data will be required to initialize a contact class session.

1. The Zingle API user's token (this is your Zingle dashboard username)
2. The Zingle API user's security key (this is your Zingle dashboard password)
3. The channel type UUID representing the chat channel being used by the API user
4. The channel value, such as the user name of the current third party app user within the custom chat type

### Initialization

#### Using contact selection and error handling blocks
```objective-c
// Initialize the session object.
session = [ZingleSDK contactSessionWithToken:myToken
					 	   			     key:myKey
							   channelTypeId:channelId
							    channelValue:username];
								
// Optionally set an error-handling block
session.error = ^(ZNGError * _Nonnull error) {
    // Do something with the error
};
	
// Connect, optionally providing a block to be called once all available contact services have been found
[session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
    // Choose a contact service and return it immediately or present the user with a choice and return nil
	//
	[self presentContactServiceChoiceToUser];
	return nil;
} completion:nil];

// ... Wait for user input ...

```

```objective-c
void userDidSelectContactService:(ZNGContactService *)selectedContactService
{
	// Choose a contact service if it was not done in the block above, optionally providing a completion block
	[session setContactService:selectedContactService completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
	    if (error == nil) {
			NSLog(@"Something went wrong")
		} else {
			// You did it!
			
			// If you would like to access the data directly, you may grab a conversation object.
		    ZNGConversation * conversation = session.conversation;

			// You may also grab a view controller that will handle message displaying and sending messages.
			ZNGConversationViewController * conversationViewController = session.conversationViewController;
			[self presentViewController:conversationViewController animated:YES completion:nil];
		}
	}];
}
```

#### Using KVO

You may instead wish to use KVO to determine when the availableContactServices array has been populated and to handle any errors.

```objective-c
session = [ZingleSDK contactSessionWithToken:myToken
					 	   			     key:myKey
							   channelTypeId:channelId
							    channelValue:username];
[session addObserver:self forKeyPath:@"availableContactServices" options:0 context:NULL];
[session addObserver:self forKeyPath:@"mostRecentError" options:0 context:NULL];

[session connect];								
```

```objective-c
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"availableContactServices"]) {
		// Present UI to the user to select a contact service
	} else if ([keyPath isEqualToString:@"mostRecentError"]) {
		// Handle an error
	}
}
```

```objective-c
void userDidSelectContactService:(ZNGContactService *)selectedContactService
{
	[session setContactService:selectedContactService completion:^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
	    if (error == nil) {
			NSLog(@"Something went wrong")
		} else {
			// You did it!
			
			// If you would like to access the data directly, you may grab a conversation object.
		    ZNGConversation * conversation = session.conversation;

			// You may also grab a view controller that will handle message displaying and sending messages.
			ZNGConversationViewController * conversationViewController = session.conversationViewController;
			[self presentViewController:conversationViewController animated:YES completion:nil];
		}
	}];
}
```

#### Using a pre-selected contact service

You may wish to immediately select a contact service on login.

```objective-c
// Initialize the session object.  This will send off a request for all available contact services.
session = [ZingleSDK contactSessionWithToken:myToken
					 	   			     key:myKey
							   channelTypeId:channelId
							    channelValue:username];

[session connectWithContactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull availableContactServices) {
    return preselectedContactService;
} completion: ^(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error) {
	if (error != nil) {
		// You did it!
	}
}];
```

## Push Notifications

Conversation objects and Conversation View Controller objects will refresh data whenever a push notification is received and sent to the SDK via NSNotification (see Receiving push notifications below)

### Preparing to receive push notifications

#### Certificates and registration

The user of the SDK must have a valid push notification entitlement/certificate in the app.  He is also responsible for registering the application's push notification capabilities on launch.  See  [Apple's Local and Remote Notification Programming Guide](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/Introduction.html) and [Ray Wenderlich's Push Notifications Tutorial](https://www.raywenderlich.com/123862/push-notifications-tutorial).

#### Setting the token

Once the application has successfully registered for push notifications, the device token needs to be set within the ZingleSDK before a ZingleSession is created.

```swift
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// ...
		application.registerForRemoteNotifications()
		// ...
	}

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        ZingleSDK.setPushNotificationDeviceToken(deviceToken)
    }
```

### Receiving push notifications

Once a ZingleSession with a valid push notification entitlement and a set device token has connected through the SDK, push notifications will be sent to the device whenever new data is received.  It is up to the SDK user to post an NSNotification so that the SDK elements can accept and react to the notification.

All ZingleSDK push notifications should include the Category value of ZingleSDK.  A push notification regarding a message will also include the contact service ID of the sender of the message as 'feedId.'  Following is a sample push notification dictionary and the Swift code to post an NSNotificationCenter notification to allow ZingleSDK elements to react to the new data.

```
{
    aps =     {
        alert =         {
            body = " Jason Nobody \nThis is the message body.";
        };
        sound = default;
    };
    feedId = "28e02b1d-a38e-4e6b-85d1-95fe29983a7d";
	category = "ZingleSDK";
}
```

```swift
    func handleRemoteNotificationDictionary(userInfo: [NSObject : AnyObject], fromApplicationState state: UIApplicationState) {
        NSNotificationCenter.defaultCenter().postNotificationName(ZNGPushNotificationReceived, object: nil, userInfo: userInfo)
	}
```

## Logging

The ZingleSDK uses the [CocoaLumberjack logging framework](https://github.com/CocoaLumberjack/CocoaLumberjack) with a specific [logging context](https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/CustomContext.md).

```C
#define ZINGLE_LOG_CONTEXT      889
```

## Zingle Object Model

Model | Description
--- | ---
ZingleSDK | Static class that provides convenience constructors for Zingle session objects
ZingleSession | Abstract class that represents a connection to the Zingle API
ZingleContactSession | Concrete subclass of ZingleSession that represents a connection to the Zingle API as a contact class user (e.g. a Hotel guest communicating with the front desk)
ZingleAccountSession | Concrete subclass of ZingleSession that represents a connection to the Zingle API as an account class user (e.g. a hotel employee)
ZNGAccount | [See Zingle Resource Overview - Account](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#account)
ZNGService | [See Zingle Resource Overview - Service](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#service)
ZNGPlan | [See Zingle Resource Overview - Plan](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#plan)
ZNGContact | [See Zingle Resource Overview - Contact](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#contact)
ZNGAvailablePhoneNumber | [See Zingle Resource Overview - Available Phone Number](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#available-phone-number)
ZNGLabel | [See Zingle Resource Overview - Label](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#label)
ZNGCustomField | [See Zingle Resource Overview - Custom Field](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field)
ZNGCustomFieldOption | [See Zingle Resource Overview Custom Field Option](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field-option)
ZNGCustomFieldValue | [See Zingle Resource Overview - Custom Field Value](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#custom-field-value)
ZNGChannelType | [See Zingle Resource Overview - Channel Type](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#channel-type)
ZNGServiceChannel | [See Zingle Resource Overview  - Service Channel](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#service-channel)
ZNGContactChannel | [See Zingle Resource Overview - Contact Channel](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#contact-channel)
ZNGMessageCorrespondent | Message Correspondents are the abstract representation of either the Sender or Recipient on a Message.
ZNGMessageAttachment | Message Attachments provide the ability to add binary data, such as images, to messages.
ZNGConversation | Model responsible for maintaining the state of a conversation between a Contact and a Service.
ZNGConversationViewController | UI that manages the conversation between a Contact and a Service.
ZNGAutomation | [See Zingle Resource Overview - Automation](https://github.com/Zingle/rest-api/blob/master/resource_overview.md#automation)
