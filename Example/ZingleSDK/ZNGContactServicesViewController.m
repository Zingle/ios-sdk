//
//  ZNGContactServicesViewController.m
//  Pods
//
//  Created by Robert Harrison on 5/27/16.
//
//

#import "ZNGContactServicesViewController.h"
#import "ZNGContactServiceClient.h"
#import "ZNGContactClient.h"
#import "ZNGContact.h"

@interface ZNGContactServicesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *contactServices;

@end

@implementation ZNGContactServicesViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGContactServicesViewController class])
                          bundle:[NSBundle bundleForClass:[ZNGContactServicesViewController class]]];
}

+ (instancetype)contactServicesViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGContactServicesViewController class])
                                          bundle:[NSBundle bundleForClass:[ZNGContactServicesViewController class]]];
}

+ (instancetype)withServiceId:(NSString *)serviceId channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue
{
    ZNGContactServicesViewController *vc = (ZNGContactServicesViewController *)[ZNGContactServicesViewController contactServicesViewController];
    
    if (vc) {
        vc.serviceId = serviceId;
        vc.channelTypeId = channelTypeId;
        vc.channelValue = channelValue;
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Services";
    
    self.contactServices = [[NSMutableArray alloc] init];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ZNGContactServiceCell"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshUI {
    
    NSDictionary *parameters = @{ @"channel_value" : self.channelValue,
                                  @"channel_type_id" : self.channelTypeId };
    
    [ZNGContactServiceClient contactServiceListWithParameters:parameters success:^(NSArray *contactServices, ZNGStatus *status) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (contactServices) {
                [self.contactServices removeAllObjects];
                [self.contactServices addObjectsFromArray:contactServices];
                
                [self.tableView reloadData];
            }
            
        });
        
        
    } failure:^(ZNGError *error) {
        NSLog(@"%@", error);
    }];
    
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contactServices.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContactService *contactService = [self.contactServices objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZNGContactServiceCell"];
    
    cell.textLabel.text = contactService.serviceDisplayName;
    
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContactService *contactService = [self.contactServices objectAtIndex:indexPath.row];
    
    if (!contactService.contactId) {
        
        [ZNGContactClient findOrCreateContactWithChannelTypeID:self.channelTypeId andChannelValue:self.channelValue withServiceId:self.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
            
            if (contact) {
                
                if (self.delegate) {
                    contactService.contactId = contact.contactId;
                    [self.delegate contactServicesViewControllerDidSelectContactService:contactService];
                }
                
            } else {
                NSLog(@"contact is nil!");
            }
            
            
        } failure:^(ZNGError *error) {
            NSLog(@"Error while attempting to findOrCreateContact: %@", error.localizedDescription);
        }];
        
        
        
    } else {
        
        if (self.delegate) {
            [self.delegate contactServicesViewControllerDidSelectContactService:contactService];
        }
        
    }

}

@end
