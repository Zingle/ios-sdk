//
//  ZNGViewController.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGViewController.h"
#import "ZingleSDK.h"

@interface ZNGViewController ()

@end

@implementation ZNGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    ZingleSDK *sdk = [ZingleSDK sharedSDK];
    [sdk setToken:@"rfarley@zingleme.com" andKey:@"13oolvler"];
    
//    [sdk accountWithId:@"bbc1f555-bc73-447b-90e5-4893e895acb7" success:^(ZNGAccount *account) {
//        NSLog(@"Account 1: %@", [account description]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error localizedDescription]);
//    }];
//    
//    [sdk accountListWithParameters:@{@"sort_direction": @"desc"} success:^(NSArray *accounts) {
//        NSLog(@"Account count: %lu",(unsigned long) [accounts count]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error localizedDescription]);
//    }];
//
//    [sdk accountPlanWithAccountId:@"bbc1f555-bc73-447b-90e5-4893e895acb7" withPlanId:@"14c602b5-202b-47b4-9753-895785c868df" success:^(ZNGAccountPlan *plan) {
//        NSLog(@"Plan 1: %@", [plan description]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error localizedDescription]);
//    }];
//    
//    [sdk accountPlanListWithAccountId:@"bbc1f555-bc73-447b-90e5-4893e895acb7" withParameters:@{@"sort_direction": @"desc"} success:^(NSArray *plans) {
//        NSLog(@"Plan count: %lu", (unsigned long)[plans count]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error localizedDescription]);
//    }];
//    
//    [sdk serviceWithId:@"e545a46e-bfcd-4db2-bfee-8e590fdcb33f" success:^(ZNGService *service) {
//        NSLog(@"Service 1: %@", [service description]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error description]);
//    }];
//    
//    [sdk serviceListWithParameters:@{@"sort_direction": @"desc"} success:^(NSArray *services) {
//        NSLog(@"Service count: %lu",(unsigned long) [services count]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error localizedDescription]);
//    }];
//    
    
//    ZNGServiceAddress *address = [[ZNGServiceAddress alloc] init];
//    address.address = @"1717 W North";
//    address.city = @"Chicago";
//    address.state = @"IL";
//    address.country = @"US";
//    address.postalCode = @"60622";
//    
//    [sdk createServiceWithAccountId:@"bbc1f555-bc73-447b-90e5-4893e895acb7" displayName:@"Test Service 1" businessName:@"Test Business 1" timeZone:@"America/Chicago" planCode:@"enterprise_platinum" serviceAddress:address success:^(ZNGService *service) {
//         NSLog(@"Service 1: %@", [service description]);
//    } failure:^(NSError *error) {
//        NSLog(@"Error: %@", [error description]);
//    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
