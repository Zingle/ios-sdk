//
//  ZNGPlan.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGPlan.h"
#import "ZingleModel.h"
#import "NSMutableDictionary+json.h"
#import "ZNGAccount.h"
#import "ZNGService.h"
#import "ZingleDAO.h"

@interface ZNGPlan()

@property (nonatomic, retain) ZNGAccount *account;

@end

@implementation ZNGPlan

- (id)initWithAccount:(ZNGAccount *)account
{
    if( self = [super init] )
    {
        self.account = account;
    }
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"accounts/%@/plans/%@", self.account.ID, self.ID];
    } else {
        return [NSString stringWithFormat:@"accounts/%@/plans", self.account.ID];
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.code = [data objectAtPath:@"code" expectedClass:[NSString class] default:@""];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    self.isPrinterPlan = [[data objectAtPath:@"is_printer_plan" expectedClass:[NSNumber class] default:[NSNumber numberWithBool:NO]] boolValue];
    self.termMonths = [data objectAtPath:@"term_months" expectedClass:[NSNumber class] default:nil];
    self.monthlyOrUnitPrice = [data objectAtPath:@"monthly_or_unit_price" expectedClass:[NSNumber class] default:nil];
    self.setupPrice = [data objectAtPath:@"setup_price" expectedClass:[NSNumber class] default:nil];
}

- (ZNGService *)newService
{
    ZNGService *service = [[ZNGService alloc] init];
    if( self.account != nil )
    {
        service.account = self.account;
    }
    service.plan = self;
    return service;
}

- (NSString *)description
{
    NSString *description = @"<ZNGPlan> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    code: %@\r", self.code];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    isPrinterPlan: %d\r", self.isPrinterPlan];
    description = [description stringByAppendingFormat:@"    termMonths: %i\r", [self.termMonths intValue]];
    description = [description stringByAppendingFormat:@"    monthlyOrUnitPrice: %f\r", [self.monthlyOrUnitPrice floatValue]];
    description = [description stringByAppendingFormat:@"    setupPrice: %f\r", [self.setupPrice floatValue]];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
