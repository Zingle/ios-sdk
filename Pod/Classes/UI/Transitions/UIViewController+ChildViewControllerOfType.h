//
//  UIViewController+ChildViewControllerOfType.h
//  ZingleSDK
//
//  Created by Jason Neel on 2/14/18.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ChildViewControllerOfType)

- (__kindof UIViewController *)childViewControllerOfType:(Class)childClass;

@end
