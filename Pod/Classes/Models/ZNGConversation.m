//
//  ZNGConversation.m
//  Pods
//
//  Created by Ryan Farley on 2/18/16.
//
//

#import "ZNGConversation.h"
#import "ZNGMessageClient.h"

@implementation ZNGConversation

- (void)updateMessages
{
    NSDictionary *params = @{@"page_size" : @100,
                             @"contact_id" : self.contact.participantId,
                             @"page" : @1,
                             @"sort_field" : @"created_at",
                             @"sort_direction" : @"desc"};
    
    [ZNGMessageClient messageListWithParameters:params withServiceId:self.service.participantId success:^(NSArray *messages, ZNGStatus* status) {
        
        self.messages = messages;
        
        int pageNumbers = status.totalPages;
        
        [self.delegate messagesUpdated];
        
        for (int i = 2; i <= pageNumbers; i++) {
            NSDictionary *params = @{@"page_size" : @100,
                                     @"contact_id" : self.contact.participantId,
                                     @"page" : @(i),
                                     @"sort_field" : @"created_at",
                                     @"sort_direction" : @"desc"};

            [ZNGMessageClient messageListWithParameters:params withServiceId:self.service.participantId success:^(NSArray *messages, ZNGStatus* status) {
                
                NSMutableArray *temp = [NSMutableArray arrayWithArray:self.messages];
                [temp addObjectsFromArray:messages];
                self.messages = temp;
                
                [self.delegate messagesUpdated];
                
            } failure:nil];
        }
        
    } failure:nil];
}

@end
