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
#import "ZNGConversationServiceToContact.h"
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
    
    UIImage * blankManImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGAssignmentViewController class]];
    blankManImage = [UIImage imageNamed:@"anonymousAvatarBig" inBundle:bundle compatibleWithTraitCollection:nil];
    
    if ([[self.contact fullName] length] > 0) {
        self.title = [NSString stringWithFormat:@"Assign %@", [self.contact fullName]];
    }
    
    teams = self.session.service.teams;
    users = [self.session usersIncludingSelf:NO];
}

- (IBAction)pressedClose:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assignmentViewWasCanceled:)]) {
        [self.delegate assignmentViewWasCanceled:self];
    }
    
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

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView * header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textAlignment = NSTextAlignmentCenter;
        header.textLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
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
                    ZNGUserAuthorization * userAuth = self.session.userAuthorization;
                    ZNGAvatarImageView * avatar = [[ZNGAvatarImageView alloc] initWithAvatarUrl:userAuth.avatarUri
                                                                                       initials:[[userAuth displayName] initials]
                                                                                           size:cell.avatarContainer.bounds.size
                                                                                backgroundColor:[UIColor zng_outgoingMessageBubbleColor]
                                                                                      textColor:[UIColor whiteColor]
                                                                                           font:[UIFont latoFontOfSize:36.0]];
                    avatar.frame = cell.avatarContainer.bounds;
                    [cell.avatarContainer addSubview:avatar];
                    
                    cell.nameLabel.text = @"You";
                    return cell;
                }
                    
                case ROW_UNASSIGN:
                {
                    ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"user" forIndexPath:indexPath];
                    cell.nameLabel.text = @"Unassign";
                    
                    UIImageView * blankAvatar = [[UIImageView alloc] initWithImage:blankManImage];
                    blankAvatar.contentMode = UIViewContentModeScaleAspectFit;
                    blankAvatar.frame = cell.avatarContainer.bounds;
                    [cell.avatarContainer addSubview:blankAvatar];

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
                                                                                   font:[UIFont latoFontOfSize:17.0]];
            
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
    switch (indexPath.section) {
        case SECTION_TOP:
            switch (indexPath.row) {
                case ROW_YOU:
                    [self.delegate userChoseToAssignContact:self.contact toUser:self.session.userAuthorization];
                    break;
                    
                case ROW_UNASSIGN:
                    [self.delegate userChoseToUnassignContact:self.contact];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
            
        case SECTION_TEAMS:
            [self.delegate userChoseToAssignContact:self.contact toTeam:teams[indexPath.row]];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
            
        case SECTION_USERS:
            [self.delegate userChoseToAssignContact:self.contact toUser:users[indexPath.row]];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
    }
}

@end
