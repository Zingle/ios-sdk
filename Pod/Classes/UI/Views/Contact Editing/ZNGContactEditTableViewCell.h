//
//  ZNGContactEditTableViewCell.h
//  Pods
//
//  Created by Jason Neel on 8/29/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGContactEditTableViewCell : UITableViewCell

/**
 *  Abstract method that should be implemented by subclasses
 */
- (void) applyInProgressChanges;

@property (nonatomic) BOOL editingLocked;

@end
