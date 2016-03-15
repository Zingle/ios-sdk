//
//  ZNGInboxViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGInboxViewController.h"
#import "ZNGContact.h"
#import "ZNGContactClient.h"
#import "ZNGTableViewCell.h"

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *contacts;

@end

@implementation ZNGInboxViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGInboxViewController class])
                          bundle:[NSBundle bundleForClass:[ZNGInboxViewController class]]];
}

+ (instancetype)inboxViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGInboxViewController class])
                                          bundle:[NSBundle bundleForClass:[ZNGInboxViewController class]]];
}

+ (instancetype)withContacts:(NSArray *)contacts
{
    ZNGInboxViewController *vc = (ZNGInboxViewController *)[ZNGInboxViewController inboxViewController];
    
    if (vc) {
        vc.contacts = contacts;
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 118.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[ZNGTableViewCell nib] forCellReuseIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    
    NSString *serviceId = @"e545a46e-bfcd-4db2-bfee-8e590fdcb33f";
    
    [ZNGContactClient contactListWithServiceId:serviceId parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        self.contacts = contacts;
        [self.tableView reloadData];
        
    } failure:^(ZNGError *error) {
        
    }];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contacts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self.contacts objectAtIndex:indexPath.row];
    ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    [cell configureCellWithContact:contact];
    [cell.labelCollectionView reloadData];
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self.contacts objectAtIndex:indexPath.row];
    
    NSString *serviceId = @"e545a46e-bfcd-4db2-bfee-8e590fdcb33f";
    NSString *contactChannelValue = @"ryans.testapp";
    
    [[ZingleSDK sharedSDK] addConversationFromContactId:contact.contactId toServiceId:serviceId contactChannelValue:contactChannelValue success:^(ZNGConversation *conversation) {
        
        ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerForConversation:conversation];
        [self.navigationController pushViewController:vc animated:YES];

        
    } failure:^(ZNGError *error) {
        // handle failure
    }];
}

@end