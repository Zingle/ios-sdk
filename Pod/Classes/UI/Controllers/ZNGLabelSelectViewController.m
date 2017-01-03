//
//  ZNGLabelSelectViewController.m
//  Pods
//
//  Created by Jason Neel on 8/25/16.
//
//

#import "ZNGLabelSelectViewController.h"
#import "ZNGLabel.h"
#import "UIFont+Lato.h"
#import "UIColor+ZingleSDK.h"

@interface ZNGLabelSelectViewController ()

@end

@implementation ZNGLabelSelectViewController
{
    NSBundle * bundle;
    NSArray<ZNGLabel *> * filteredLabels;
    
    UISearchController * searchController;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    bundle = [NSBundle bundleForClass:[self class]];
    
    // For some reason UIAppearance does not work for these buttons, possibly because they were manually placed in IB instead of being auto generated as part
    //  of a nav controller.
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:17.0] };
    [self.cancelButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    
    searchController.searchBar.barTintColor = [UIColor zng_lightBlue];
    
    self.tableView.tableHeaderView = searchController.searchBar;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions
- (IBAction)pressedCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) didSelectLabel:(ZNGLabel *)label
{
    [self.delegate labelSelectViewController:self didSelectLabel:label];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Data
- (NSArray<ZNGLabel *> *) currentLabelData
{
    return (searchController.active) ? filteredLabels : self.labels;
}

- (ZNGLabel *)labelForIndexPath:(NSIndexPath *)indexPath
{
    NSArray<ZNGLabel *> * relevantLabels = [self currentLabelData];
    return (indexPath.row < [relevantLabels count]) ? relevantLabels[indexPath.row] : nil;
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self currentLabelData] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellID = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.textLabel.font = [UIFont latoFontOfSize:17.0];
    }
    
    ZNGLabel * label = [self labelForIndexPath:indexPath];
    cell.textLabel.text = label.displayName;
    
    UIImage * labelImage = [UIImage imageNamed:@"editIconLabels" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImageView * imageView = [[UIImageView alloc] initWithImage:labelImage];
    imageView.tintColor = label.backgroundUIColor;
    
    cell.accessoryView = imageView;
    
    return cell;
}

#pragma mark - Table view delegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGLabel * label = [self labelForIndexPath:indexPath];
    [self.delegate labelSelectViewController:self didSelectLabel:label];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Searching
- (void) updateSearchResultsForSearchController:(UISearchController *)aSearchController
{
    filteredLabels = [self labelsMatchingSearchText:aSearchController.searchBar.text];
    [self.tableView reloadData];
}

- (NSArray<ZNGLabel *> *) labelsMatchingSearchText:(NSString *)text
{
    if ([text length] == 0) {
        return self.labels;
    }
    
    NSString * term = [text lowercaseString];
    NSMutableArray<ZNGLabel *> * matchingLabels = [[NSMutableArray alloc] initWithCapacity:[self.labels count]];
    
    for (ZNGLabel * label in self.labels) {
        if ([[label.displayName lowercaseString] containsString:term]) {
            [matchingLabels addObject:label];
        }
    }
    
    return matchingLabels;
}

@end
