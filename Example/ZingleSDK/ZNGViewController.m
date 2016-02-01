//
//  ZNGViewController.m
//  ZingleSDK
//
//  Created by Ryan Farley on 02/01/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGViewController.h"
#import "ZNGQuickStart.h"

@interface ZNGViewController ()

@end

@implementation ZNGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ZNGQuickStart *test = [[ZNGQuickStart alloc] init];
    [test startAsynchronousTest];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
