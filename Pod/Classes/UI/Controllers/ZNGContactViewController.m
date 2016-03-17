//
//  ZNGContactViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import "ZNGContactViewController.h"
#import "ZNGContactDetailsTableViewCell.h"
#import "ZNGContactLabelsTableViewCell.h"
#import "ZNGContactCustomFieldTableViewCell.h"

@interface ZNGContactViewController ()

@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) ZNGService *service;

@end

@implementation ZNGContactViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGContactViewController class])
                          bundle:[NSBundle bundleForClass:[ZNGContactViewController class]]];
}

+ (instancetype)contactViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGContactViewController class])
                                          bundle:[NSBundle bundleForClass:[ZNGContactViewController class]]];
}

+ (instancetype)withContact:(ZNGContact *)contact withService:(ZNGService *)service
{
    ZNGContactViewController *vc = (ZNGContactViewController *)[ZNGContactViewController contactViewController];
    
    if (vc) {
        vc.contact = contact;
        vc.service = service;
        
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.contact fullName];
    
    [self.tableView registerNib:[ZNGContactDetailsTableViewCell nib] forCellReuseIdentifier:[ZNGContactDetailsTableViewCell cellReuseIdentifier]];
    [self.tableView registerNib:[ZNGContactLabelsTableViewCell nib] forCellReuseIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier]];
    [self.tableView registerNib:[ZNGContactCustomFieldTableViewCell nib] forCellReuseIdentifier:[ZNGContactCustomFieldTableViewCell cellReuseIdentifier]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return [self.contact.labels count] + 1;
            break;
        case 2:
            if ([self.service.contactCustomFields count] == 3) {
                return 0;
            }
            return [self.service.contactCustomFields count];
            break;
        case 3:
            return 1;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        ZNGContactDetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactDetailsTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
        
        if (indexPath.row == 0) {
            [cell configureCellWithField:[self.contact title] withPlaceholder:@"Title"];
        } else if (indexPath.row == 1) {
            [cell configureCellWithField:[self.contact firstName] withPlaceholder:@"First name"];
        } else if (indexPath.row == 2) {
            [cell configureCellWithField:[self.contact lastName] withPlaceholder:@"Last name"];
        } else if (indexPath.row == 3) {
            [cell configureCellWithField:[self.contact phoneNumber] withPlaceholder:@"Phone number"];
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        if (indexPath.row == [self.contact.labels count]) {
            ZNGContactLabelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
            [cell configureAddMoreLabel];
            return cell;
        }
        ZNGContactLabelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
        ZNGLabel *label = [self.contact.labels objectAtIndex:indexPath.row];
        [cell configureCellWithLabel:label];
        return cell;
    } else if (indexPath.section == 2) {
        ZNGContactCustomFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactCustomFieldTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
        ZNGContactField *field = [self.service.contactCustomFields objectAtIndex:indexPath.row];
        [cell configureCellWithField:field andValues:self.contact.customFieldValues];
        return cell;
        
    } else if (indexPath.section == 3) {
        ZNGContactLabelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
        [cell configureDeleteContactLabel];
        return cell;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        ZNGContactField *field = [self.service.contactCustomFields objectAtIndex:indexPath.row];
        if ([field.displayName isEqualToString:@"First Name"] || [field.displayName isEqualToString:@"Last Name"] || [field.displayName isEqualToString:@"Title"]) {
            return 0;
        }
    }
    return 44;
}

@end
