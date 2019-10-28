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
#import "ZNGLabelTableViewCell.h"
#import "ZNGDashedBorderLabel.h"

static NSString * const LabelCellId = @"labelCell";

@interface ZNGLabelSelectViewController ()

@end

@implementation ZNGLabelSelectViewController
{
    NSArray<ZNGLabel *> * filteredLabels;
    
    UIImage * labelIcon;
    
    UISearchController * searchController;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGLabelSelectViewController class]];
    labelIcon = [[UIImage imageNamed:@"editIconLabels" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UINib * labelCellNib = [UINib nibWithNibName:NSStringFromClass([ZNGLabelTableViewCell class]) bundle:bundle];
    [self.tableView registerNib:labelCellNib forCellReuseIdentifier:LabelCellId];
    
    self.tableView.estimatedRowHeight = 42.0;
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    
    searchController.searchBar.tintColor = [UIColor whiteColor];
    
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
    ZNGLabelTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:LabelCellId forIndexPath:indexPath];
    ZNGLabel * label = [self labelForIndexPath:indexPath];
    
    UIColor * foregroundColor = [label textUIColor];
    cell.labelLabel.textColor = foregroundColor;
    cell.labelLabel.borderColor = foregroundColor;
    cell.labelLabel.backgroundColor = [label backgroundUIColor];
    
    NSTextAttachment * iconAttachment = [[NSTextAttachment alloc] init];
    iconAttachment.image = labelIcon;
    iconAttachment.bounds = CGRectMake(0.0, cell.labelLabel.font.descender, labelIcon.size.width, labelIcon.size.height);
    NSAttributedString * iconString = [NSAttributedString attributedStringWithAttachment:iconAttachment];
    
    // Add a leading space, otherwise tinting the NSTextAttachment does not work
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:@" "];
    [text appendAttributedString:iconString];
    NSString * displayNameWithPadding = [NSString stringWithFormat:@"  %@  ", [label.displayName uppercaseString]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:displayNameWithPadding]];
   
    cell.labelLabel.attributedText = text;

    return cell;
}

#pragma mark - Table view delegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGLabel * label = [self labelForIndexPath:indexPath];
    [self.delegate labelSelectViewController:self didSelectLabel:label];
    
    [searchController dismissViewControllerAnimated:NO completion:nil];
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
