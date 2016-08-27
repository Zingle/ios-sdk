//
//  ZNGLabelSelectViewController.h
//  Pods
//
//  Created by Jason Neel on 8/25/16.
//
//

#import <UIKit/UIKit.h>

@class ZNGLabel;
@class ZNGLabelSelectViewController;

@protocol ZNGLabelSelectionDelegate <NSObject>

- (void) labelSelectViewController:(ZNGLabelSelectViewController *)viewController didSelectLabel:(ZNGLabel *)label;

@end

@interface ZNGLabelSelectViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

- (IBAction)pressedCancel:(id)sender;

@property (nonatomic, strong) NSArray<ZNGLabel *> * labels;
@property (nonatomic, weak) id <ZNGLabelSelectionDelegate> delegate;

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * cancelButton;

@end
