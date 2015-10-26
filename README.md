# Zingle iOS SDK

## Overview

Zingle is a multi-channel communications platform that allows the sending, receiving and automating of conversations between a Business and a Customer.  Zingle is typically interacted with by Businesses via a web browser to manage these conversations with their customers.  The Zingle API provides functionality to developers to act on behalf of either the Business or the Customer.  The Zingle iOS SDK provides mobile application developers an easy-to-use layer on top of the Zingle API.

To view the latest API documentation, please refer to: https://github.com/Zingle/rest-api/

### Integrated UI

In addition to the standard API conveniences, the iOS SDK also provides an easy to use User Interface to automate the conversation between a Contact and a Service.  The UI is fully customizeable to your needs, and can be used on behalf of the Contact, or on behalf of the Zingle Service.

![](https://github.com/Zingle/ios-sdk/blob/master/Assets/message_layout.png)

UI Examples

```obj-c
[[ZingleSDK sharedSDK] setToken:@"dpeace+4S@zingle.me" andKey:@"sPaTud8x@w?y"];
[[ZingleSDK sharedSDK] useServiceWithID:serviceID error:nil];
ZNGConversationViewController *chatViewController = [[ZNGConversationViewController alloc] initWithChannelTypeName:@"Contact ID" from:@"123456"];

// OPTIONAL UI SETTINGS
chatViewController.inboundBackgroundColor = [UIColor colorWithRed:225.0f/255.0f green:225.0f/255.0f blue:225.0f/255.0f alpha:1.0f];
chatViewController.outboundBackgroundColor = [UIColor colorWithRed:229.0f/255.0f green:245.0f/255.0f blue:252.0f/255.0f alpha:1.0f];
chatViewController.inboundTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
chatViewController.outboundTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
chatViewController.authorTextColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
chatViewController.messageHorziontalMargin = 25;
chatViewController.messageVerticalMargin = 8;
chatViewController.messageIndentAmount = 40;
chatViewController.bodyPadding = 14;
chatViewController.cornerRadius = 10;
chatViewController.arrowOffset = 10;
chatViewController.arrowSize = CGSizeMake(20, 10);
chatViewController.fromName = @"Me";
chatViewController.toName = @"Received";

[self presentViewController:chatViewController animated:YES completion:nil];
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

### QuickStarts

#### Synchronous

To view Quick Start using synchronous examples, please see: [SynchronousQuickStart.md](Examples/SynchronousQuickStart.md)

#### Asynchronous

To view Quick Start using asynchronous examples, please see: [AsynchronousQuickStart.md](Examples/AsynchronousQuickStart.md)
