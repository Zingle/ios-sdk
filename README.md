# Zingle iOS SDK

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/

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

pod 'ZingleSDK', '~> 0.2'
```

Then, run the following command:

```bash
$ pod install
```

Import the SDK header file where needed:
```objective-c
#import <ZingleSDK/ZingleSDK.h>
```

### Integrated UI

In addition to the standard API conveniences, the iOS SDK also provides an easy to use User Interface to automate the conversation between a Contact and a Service.  The UI is fully customizeable to your needs, and can be used on behalf of the Contact, or on behalf of the Zingle Service.

![](https://github.com/Zingle/ios-sdk/blob/master/Assets/message_layout.png)

UI Examples

```obj-c

// Initialize basic auth for connecting to API.
[[ZingleSDK sharedSDK] setToken:token andKey:key];

// Registers a new conversation in ZingleSDK.
[[ZingleSDK sharedSDK] addConversationFromContactId:contactId 
										toServiceId:serviceId 
								contactChannelValue:contactChannelValue 
								            success:^(ZNGConversation *conversation) {
    
    // Returns a new conversation view controller for the specified conversation.
    ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerForConversation:conversation];
    [self presentViewController:vc animated:YES completion:nil];

} failure:^(ZNGError *error) {
    // handle failure
}];

// OPTIONAL UI SETTINGS
ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerForConversation:conversation];

vc.incomingBubbleColor = [UIColor orangeColor];
vc.outgoingBubbleColor = [UIColor blueColor];
vc.incomingTextColor = [UIColor blackColor];
vc.outgoingTextColor = [UIColor whiteColor];
vc.authorTextColor = [UIColor blackColor];
vc.senderName = @"Sender name";
vc.receiverName = @"Receiver name";

[self presentViewController:vc animated:YES completion:nil];
```

### Zingle Object Model

Model | Description
--- | ---
ZingleSDK | A singleton master object that holds the credentials, stateful information, and the distribution of notifications in the ZingleSDK.
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

### Examples

#### Creating a list of conversations

The example app loads the same conversation from the perspective of the contact and the service respectively. You will need to supply your own values for the following variables in [ZNGAppDelegate.m](Example/ZingleSDK/ZNGAppDelegate.m):
```obj-c
NSString *token = @“TOKEN”;
NSString *key = @“KEY”;
NSString *contactChannelValue = @“test.app”;
NSString *contactId = @“CONTACT ID”;
NSString *serviceId = @“SERVICE ID”;
```
Please direct any inquiries about the SDK and examples to rfarley@zingleme.com or your account manager.