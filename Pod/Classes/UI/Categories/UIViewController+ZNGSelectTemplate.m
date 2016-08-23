//
//  UIViewController+ZNGSelectTemplate.m
//  Pods
//
//  Created by Jason Neel on 8/4/16.
//
//

#import "UIViewController+ZNGSelectTemplate.h"
#import "ZNGTemplate.h"

@implementation UIViewController (ZNGSelectTemplate)

- (void) presentUserWithChoiceOfTemplate:(NSArray<ZNGTemplate *> *)templates completion:(void (^)(NSString * _Nullable selectedTemplateBody))completion
{
    NSParameterAssert(completion);
    
    UIAlertController * templateSelectAlert = [UIAlertController alertControllerWithTitle:@"Select a template" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZNGTemplate * template in templates) {
        UIAlertAction * action = [UIAlertAction actionWithTitle:template.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (![template requiresResponseTime]) {
                // This template requires no further information.  It's callback time.
                completion(template.body);
            } else {
                // This template requires a response time
                UIAlertController * responseTimeSelectAlert = [UIAlertController alertControllerWithTitle:@"Select a response time" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                NSArray<NSString *> * responseTimes = [template responseTimeChoices];
                
                for (NSString * time in responseTimes) {
                    UIAlertAction * action = [UIAlertAction actionWithTitle:time style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSString * body = [template bodyWithResponseTime:time];
                        completion(body);
                    }];
                    [responseTimeSelectAlert addAction:action];
                }
                
                UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    completion(nil);
                }];
                [responseTimeSelectAlert addAction:cancel];
                
                [self presentViewController:responseTimeSelectAlert animated:YES completion:nil];
            }
        }];
        [templateSelectAlert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(nil);
    }];
    [templateSelectAlert addAction:cancel];
    
    [self presentViewController:templateSelectAlert animated:YES completion:nil];
}


@end