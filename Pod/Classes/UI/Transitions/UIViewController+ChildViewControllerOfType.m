//
//  UIViewController+ChildViewControllerOfType.m
//  ZingleSDK
//
//  Created by Jason Neel on 2/14/18.
//

#import "UIViewController+ChildViewControllerOfType.h"

@implementation UIViewController (ChildViewControllerOfType)

- (__kindof UIViewController *)childViewControllerOfType:(Class)childClass
{
    for (UIViewController * child in self.childViewControllers) {
        if ([child isKindOfClass:childClass]) {
            return child;
        }
        
        UIViewController * foundChild = [child childViewControllerOfType:childClass];
        
        if (foundChild != nil) {
            return foundChild;
        }
    }
    
    return nil;
}

@end
