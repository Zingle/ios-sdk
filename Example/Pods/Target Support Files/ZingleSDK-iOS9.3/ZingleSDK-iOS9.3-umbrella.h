#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ZNGAccountClient.h"
#import "ZNGAutomationClient.h"
#import "ZNGBaseClient.h"
#import "ZNGBaseClientService.h"
#import "ZNGContactClient.h"
#import "ZNGContactServiceClient.h"
#import "ZNGEventClient.h"
#import "ZNGHotsosClient.h"
#import "ZNGLabelClient.h"
#import "ZNGMessageClient.h"
#import "ZNGNotificationsClient.h"
#import "ZNGServiceClient.h"
#import "ZNGTemplateClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGAnalytics.h"
#import "ZNGColoredLogFormatter.h"
#import "ZNGLogFormatter.h"
#import "ZNGLogging.h"
#import "ZNGAccount.h"
#import "ZNGAccountPlan.h"
#import "ZNGAutomation.h"
#import "ZNGAvailablePhoneNumber.h"
#import "ZNGChannel.h"
#import "ZNGChannelType.h"
#import "ZNGContact.h"
#import "ZNGInboxDataClosed.h"
#import "ZNGInboxDataConfirmed.h"
#import "ZNGInboxDataFilters.h"
#import "ZNGInboxDataLabel.h"
#import "ZNGInboxDataOpen.h"
#import "ZNGInboxDataSearch.h"
#import "ZNGInboxDataSet.h"
#import "ZNGInboxDataUnconfirmed.h"
#import "ZNGNewContact.h"
#import "ZNGContactField.h"
#import "ZNGContactFieldValue.h"
#import "ZNGNewContactFieldValue.h"
#import "ZNGContactService.h"
#import "ZNGCorrespondent.h"
#import "ZNGError.h"
#import "ZNGEvent.h"
#import "ZNGFieldOption.h"
#import "ZNGLabel.h"
#import "ZNGMessage.h"
#import "ZNGMessageForwardingRequest.h"
#import "ZNGNewMessage.h"
#import "ZNGNewMessageResponse.h"
#import "ZNGMessageRead.h"
#import "ZNGNewChannel.h"
#import "ZNGNewEvent.h"
#import "ZNGNotificationRegistration.h"
#import "ZNGParticipant.h"
#import "ZNGPrinter.h"
#import "ZNGNewService.h"
#import "ZNGService.h"
#import "ZNGServiceAddress.h"
#import "ZNGSetting.h"
#import "ZNGSettingsField.h"
#import "ZNGStatus.h"
#import "ZNGTemplate.h"
#import "ZNGUser.h"
#import "ZNGUserAuthorization.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"
#import "UIImage+ZingleSDK.h"
#import "UIViewController+ZNGSelectTemplate.h"
#import "ZNGContactEditViewController.h"
#import "ZNGContactToServiceViewController.h"
#import "ZNGConversationViewController.h"
#import "ZNGForwardingViewController.h"
#import "ZNGImageViewController.h"
#import "ZNGInboxViewController.h"
#import "ZNGLabelSelectViewController.h"
#import "ZNGServiceToContactViewController.h"
#import "ZNGBubblesSizeCalculator.h"
#import "ZNGContactLabelFlowLayout.h"
#import "ZNGConversationFlowLayout.h"
#import "ZNGConversationTimestampFormatter.h"
#import "ZNGImageAttachment.h"
#import "ZNGConversation.h"
#import "ZNGConversationContactToService.h"
#import "ZNGConversationDetailedEvents.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGContactChannelTableViewCell.h"
#import "ZNGContactCustomFieldTableViewCell.h"
#import "ZNGContactEditFloatLabeledTextField.h"
#import "ZNGContactEditTableViewCell.h"
#import "ZNGContactLabelsTableViewCell.h"
#import "ZNGContactPhoneNumberTableViewCell.h"
#import "ZNGConversationInputToolbar.h"
#import "ZNGConversationTextView.h"
#import "ZNGConversationToolbarContentView.h"
#import "ZNGDashedBorderLabel.h"
#import "ZNGEditContactHeader.h"
#import "ZNGEventCollectionViewCell.h"
#import "ZNGForwardingInputToolbar.h"
#import "ZNGGradientLoadingView.h"
#import "ZNGLabelCollectionViewCell.h"
#import "ZNGLabelCollectionViewFlowLayout.h"
#import "ZNGLabelGridView.h"
#import "ZNGLabelRoundedCollectionViewCell.h"
#import "ZNGNewMessageInputToolbar.h"
#import "ZNGPulsatingBarButtonImage.h"
#import "ZNGServiceConversationInputToolbar.h"
#import "ZNGTableViewCell.h"
#import "ZingleValueTransformers.h"
#import "ZingleAccountSession.h"
#import "ZingleContactSession.h"
#import "ZingleSDK.h"
#import "ZingleSession.h"

FOUNDATION_EXPORT double ZingleSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char ZingleSDKVersionString[];

