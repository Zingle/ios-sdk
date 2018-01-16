//
//  ZNGAssignmentViewController.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/11/18.
//

#import "ZNGAssignmentViewController.h"
#import "NSString+Initials.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"
#import "ZingleAccountSession.h"
#import "ZNGAssignTeamTableViewCell.h"
#import "ZNGAssignUserTableViewCell.h"
#import "ZNGAvatarImageView.h"
#import "ZNGLogging.h"
#import "ZNGTeam.h"
#import "ZNGUser.h"
#import "ZNGUserAuthorization.h"

static const int zngLogLevel = ZNGLogLevelInfo;

@interface ZNGAssignmentViewController ()

@end

enum Sections {
    SECTION_TOP,
    SECTION_TEAMS,
    SECTION_USERS,
    SECTION_TOTAL
};

enum TopSectionRows {
    ROW_YOU,
    ROW_UNASSIGN,
    ROW_TOTAL
};

@implementation ZNGAssignmentViewController
{
    NSArray<ZNGTeam *> * teams;
    NSArray<ZNGUser *> * users;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    teams = self.session.teamsVisibleToCurrentUser;
    
    // TODO: Populate users list
}

- (IBAction)pressedClose:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_TOTAL;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
    case SECTION_TOP:
        return ROW_TOTAL; // You/Unassign
        
    case SECTION_TEAMS:
        return [teams count];
        
    case SECTION_USERS:
        return [users count];
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_TEAMS:
            return @"TEAMS";
            
        case SECTION_USERS:
            return @"TEAMMATES";
            
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SECTION_TOP:
            switch (indexPath.row) {
                case ROW_YOU:
                {
                    ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"user" forIndexPath:indexPath];
                    ZNGAvatarImageView * avatar = [[ZNGAvatarImageView alloc] initWithAvatarUrl:self.session.userAuthorization.avatarUri
                                                                                       initials:[[self.session.userAuthorization displayName] initials]
                                                                                           size:cell.avatarContainer.bounds.size
                                                                                backgroundColor:[UIColor zng_outgoingMessageBubbleColor]
                                                                                      textColor:[UIColor whiteColor]
                                                                                           font:[UIFont latoFontOfSize:36.0]];
                    avatar.frame = cell.avatarContainer.bounds;
                    [cell.avatarContainer addSubview:avatar];
                    
                    cell.nameLabel.text = [self.session.userAuthorization displayName];
                    return cell;
                }
                    
                case ROW_UNASSIGN:
                {
                    ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"user" forIndexPath:indexPath];
                    cell.nameLabel.text = @"Unassigned";
                    return cell;
                }
            }
            
        case SECTION_TEAMS:
        {
            ZNGAssignTeamTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"team" forIndexPath:indexPath];
            ZNGTeam * team = teams[indexPath.row];
            
            cell.emojiLabel.text = team.emoji;
            cell.nameLabel.text = team.displayName;
            
            return cell;
        }
            
        case SECTION_USERS:
        {
            ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"user" forIndexPath:indexPath];
            ZNGUser * user = users[indexPath.row];
            
            ZNGAvatarImageView * avatar = [[ZNGAvatarImageView alloc] initWithAvatarUrl:user.avatarUri
                                                                               initials:[[user fullName] initials]
                                                                                   size:cell.avatarContainer.bounds.size
                                                                        backgroundColor:[UIColor zng_outgoingMessageBubbleColor]
                                                                              textColor:[UIColor whiteColor]
                                                                                   font:[UIFont latoFontOfSize:36.0]];
            
            [cell.avatarContainer addSubview:avatar];
            cell.nameLabel.text = [user fullName];
            
            return cell;
        }
    }
    
    ZNGLogError(@"Unexpected indexPath of %@ in ZNGAssignmentViewController %s", indexPath, __PRETTY_FUNCTION__);
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Implement
}

@end
