//
//  UIViewController+ZNGSelectTemplate.h
//  Pods
//
//  Created by Jason Neel on 8/4/16.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZNGTemplate;

@interface UIViewController (ZNGSelectTemplate)

/**
 *  Presents the user with a selection dialog for all provided templates.  Prompts the user for response time value if appropriate to the template.
 */
- (void) presentUserWithChoiceOfTemplate:(NSArray<ZNGTemplate *> *)templates completion:(void (^)(NSString * _Nullable selectedTemplateBody))completion;

NS_ASSUME_NONNULL_END

@end
