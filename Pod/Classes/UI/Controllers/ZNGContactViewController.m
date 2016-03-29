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
#import "ZNGcontactClient.h"
#import "ZNGContactChannelClient.h"
#import "ZNGFieldOption.h"
#import "ZNGContactFieldClient.h"

@interface ZNGContactViewController () <UITextFieldDelegate>

@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) ZNGService *service;

@property (nonatomic, strong) NSString *previousFirstName;
@property (nonatomic, strong) NSString *previousLastName;
@property (nonatomic, strong) NSString *previousPhoneNumber;
@property (nonatomic ,strong) NSString *previousTitle;

@property (nonnull, strong) NSArray *extraCustomFields;

@property (strong, nonatomic) UIPickerView *pickerView;

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
    
    self.previousTitle = [self.contact titleFieldValue].value;
    self.previousFirstName = [self.contact firstNameFieldValue].value;
    self.previousLastName = [self.contact lastNameFieldValue].value;
    self.previousPhoneNumber = [self.contact phoneNumberChannel].formattedValue;
    
    [self.tableView registerNib:[ZNGContactDetailsTableViewCell nib] forCellReuseIdentifier:[ZNGContactDetailsTableViewCell cellReuseIdentifier]];
    [self.tableView registerNib:[ZNGContactLabelsTableViewCell nib] forCellReuseIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier]];
    [self.tableView registerNib:[ZNGContactCustomFieldTableViewCell nib] forCellReuseIdentifier:[ZNGContactCustomFieldTableViewCell cellReuseIdentifier]];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    [self extractExtraCustomFields];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ZNGContactField *)titleCustomField
{
    for (ZNGContactField *contactField in self.service.contactCustomFields) {
        if ([contactField.displayName isEqualToString:@"Title"]) {
            return contactField;
        }
    }
    return nil;
}

- (ZNGContactField *)firstNameCustomField
{
    for (ZNGContactField *contactField in self.service.contactCustomFields) {
        if ([contactField.displayName isEqualToString:@"First Name"]) {
            return contactField;
        }
    }
    return nil;
}

- (ZNGContactField *)lastNameCustomField
{
    for (ZNGContactField *contactField in self.service.contactCustomFields) {
        if ([contactField.displayName isEqualToString:@"Last Name"]) {
            return contactField;
        }
    }
    return nil;
}

-(ZNGChannel *)phoneNumberChannel
{
    for (ZNGChannel *channel in self.service.channels) {
        if ([channel.channelType.typeClass isEqualToString:@"PhoneNumber"]) {
            return channel;
        }
    }
    return nil;
}

- (void)extractExtraCustomFields {
    NSMutableArray *extractedFields = [[NSMutableArray alloc] init];
    for (ZNGContactField *contactField in self.service.contactCustomFields) {
        if ([contactField.displayName isEqualToString:@"First Name"] ||
            [contactField.displayName isEqualToString:@"Last Name"] ||
            [contactField.displayName isEqualToString:@"Title"]) {
            continue;
        } else {
            [extractedFields addObject:contactField];
        }
    }
    self.extraCustomFields = extractedFields;
    [self.tableView reloadData];
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
            return [self.extraCustomFields count];
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
            [cell configureCellWithField:[self.contact titleFieldValue].value withPlaceholder:@"Title" withIndexPath:indexPath withDelegate:self];
            [cell setTextFieldInputView:self.pickerView];
        } else if (indexPath.row == 1) {
            [cell configureCellWithField:[self.contact firstNameFieldValue].value withPlaceholder:@"First name" withIndexPath:indexPath withDelegate:self];
        } else if (indexPath.row == 2) {
            [cell configureCellWithField:[self.contact lastNameFieldValue].value withPlaceholder:@"Last name" withIndexPath:indexPath withDelegate:self];
        } else if (indexPath.row == 3) {
            [cell configureCellWithField:[self.contact phoneNumberChannel].formattedValue withPlaceholder:@"Phone number" withIndexPath:indexPath withDelegate:self];
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
        ZNGContactField *field = [self.extraCustomFields objectAtIndex:indexPath.row];
        [cell configureCellWithField:field withValues:self.contact.customFieldValues withIndexPath:indexPath withDelegate:self];
        return cell;
        
    } else if (indexPath.section == 3) {
        ZNGContactLabelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGContactLabelsTableViewCell cellReuseIdentifier] forIndexPath:indexPath];
        [cell configureDeleteContactLabel];
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            break;
            
        case 1:
            // handle the labels
            break;
            
        case 2:
            break;
            
        case 3:
        {
            [[[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this contact?"
                                        message:nil
                                       delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Delete", nil] show];
        }
            
            break;
            
        default:
            break;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    switch (textField.superview.tag) {
        case 0:
            switch (textField.tag) {
                case 0:
                    if (![[self.contact titleFieldValue].value isEqualToString:self.previousTitle]) {
                        
                        ZNGNewContactFieldValue *updatedField = [[ZNGNewContactFieldValue alloc] init];
                        updatedField.customFieldOptionId = [self.contact titleFieldValue].selectedCustomFieldOptionId;
                        [ZNGContactClient updateContactFieldValue:updatedField withContactFieldId:[self titleCustomField].contactFieldId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
                            self.contact = contact;
                            self.title = [self.contact fullName];
                            self.previousTitle = [self.contact titleFieldValue].value;
                        } failure:^(ZNGError *error) {
                            [self showAlertForError:error];
                        }];
                    }
                    break;
                    
                case 1:
                    if (![textField.text isEqualToString:self.previousFirstName] && textField.text.length > 0) {
                        
                        [self.contact firstNameFieldValue].value = textField.text;
                        ZNGNewContactFieldValue *updatedField = [[ZNGNewContactFieldValue alloc] init];
                        updatedField.value = textField.text;
                        [ZNGContactClient updateContactFieldValue:updatedField withContactFieldId:[self firstNameCustomField].contactFieldId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
                            self.contact = contact;
                            self.title = [self.contact fullName];
                            self.previousFirstName = [self.contact firstNameFieldValue].value;
                        } failure:^(ZNGError *error) {
                            [self showAlertForError:error];
                        }];
                    }
                    break;
                    
                case 2:
                    if (![textField.text isEqualToString:self.previousLastName] && textField.text.length > 0) {
                        
                        [self.contact lastNameFieldValue].value = textField.text;
                        ZNGNewContactFieldValue *updatedField = [[ZNGNewContactFieldValue alloc] init];
                        updatedField.value = textField.text;
                        [ZNGContactClient updateContactFieldValue:updatedField withContactFieldId:[self lastNameCustomField].contactFieldId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
                            self.contact = contact;
                            self.title = [self.contact fullName];
                            self.previousLastName = [self.contact lastNameFieldValue].value;
                        } failure:^(ZNGError *error) {
                            [self showAlertForError:error];
                        }];
                    }
                    break;
                    
                case 3:
                    if (![textField.text isEqualToString:self.previousPhoneNumber] && textField.text.length > 0) {
                        if ([self.contact phoneNumberChannel] == nil) {
                            
                            ZNGNewChannel *newChannel = [[ZNGNewChannel alloc] init];
                            newChannel.channelTypeId = [self phoneNumberChannel].channelType.channelTypeId;
                            newChannel.value = textField.text;
                            newChannel.country = @"US";
                            newChannel.displayName = [self phoneNumberChannel].displayName;
                            newChannel.isDefaultForType = [self phoneNumberChannel].isDefaultForType;
                            [ZNGContactChannelClient saveContactChannel:newChannel withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGChannel *contactChannel, ZNGStatus *status) {
                                
                                NSMutableArray *temp = [NSMutableArray arrayWithArray:self.contact.channels];
                                [temp addObject:contactChannel];
                                self.contact.channels = temp;
                                textField.text = contactChannel.formattedValue;
                                
                            } failure:^(ZNGError *error) {
                                [self showAlertForError:error];
                            }];
                            
                        } else {
                            [ZNGContactChannelClient deleteContactChannelWithId:[self.contact phoneNumberChannel].channelId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGStatus *status) {
                                
                                NSMutableArray *temp = [NSMutableArray arrayWithArray:self.contact.channels];
                                [temp removeObject:[self.contact phoneNumberChannel]];
                                self.contact.channels = temp;
                                
                                if (textField.text.length > 0) {
                                    ZNGNewChannel *newChannel = [[ZNGNewChannel alloc] init];
                                    newChannel.channelTypeId = [self.contact phoneNumberChannel].channelType.channelTypeId;
                                    newChannel.value = textField.text;
                                    newChannel.country = @"US";
                                    newChannel.displayName = [self.contact phoneNumberChannel].displayName;
                                    newChannel.isDefaultForType = [self.contact phoneNumberChannel].isDefaultForType;
                                    
                                    [ZNGContactChannelClient saveContactChannel:newChannel withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGChannel *contactChannel, ZNGStatus *status) {
                                        
                                        NSMutableArray *temp = [NSMutableArray arrayWithArray:self.contact.channels];
                                        [temp addObject:contactChannel];
                                        self.contact.channels = temp;
                                        textField.text = contactChannel.formattedValue;
                                        
                                    } failure:^(ZNGError *error) {
                                        [self showAlertForError:error];
                                    }];
                                }
                            } failure:^(ZNGError *error) {
                                [self showAlertForError:error];
                            }];
                        }
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 2:
        {
            ZNGContactField *field = [self.extraCustomFields objectAtIndex:textField.tag];
            for (ZNGContactFieldValue *value in self.contact.customFieldValues) {
                if ([value.customField.contactFieldId isEqualToString:field.contactFieldId]) {
                    value.value = textField.text;
                }
            }
            ZNGNewContactFieldValue *updatedField = [[ZNGNewContactFieldValue alloc] init];
            updatedField.value = textField.text;
            [ZNGContactClient updateContactFieldValue:updatedField withContactFieldId:field.contactFieldId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
                self.contact = contact;
            } failure:^(ZNGError *error) {
                [self showAlertForError:error];
            }];
            break;
        }
            
        default:
            break;
    }
    
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField.tag != 3) {
        return YES;
    }
    BOOL result = YES;
    if (string.length != 0) {
        NSMutableString *text = [NSMutableString stringWithString:[[textField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""]];
        [text insertString:@"(" atIndex:0];
        
        if (text.length > 3)
            [text insertString:@") " atIndex:4];
        
        if (text.length > 8)
            [text insertString:@"-" atIndex:9];
        
        if (text.length > 13) {
            text = [NSMutableString stringWithString:[text substringToIndex:14]];
            result = NO;
        }
        textField.text = text;
    }
    
    return result;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [[self titleCustomField].options count];
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    ZNGFieldOption *option = [[self titleCustomField].options objectAtIndex:row];
    if ([option.value isEqualToString:@""]) {
        return @"No title";
    }
    return option.value;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    ZNGFieldOption *option = [[self titleCustomField].options objectAtIndex:row];
    ZNGContactFieldValue *fieldValue = [[ZNGContactFieldValue alloc] init];
    [self.contact titleFieldValue].value = option.value;
    [self.contact titleFieldValue].selectedCustomFieldOptionId = option.optionId;
    [self.tableView reloadData];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        return;
    }
    [ZNGContactClient deleteContactWithId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGStatus *status) {
        self.contact.contactId = @"DELETED";
        Class targetClass = NSClassFromString(@"ZNGInboxViewController");
        int indx = 0;
        for(UIViewController *viewController in self.navigationController.viewControllers){
            if([viewController isKindOfClass:targetClass]){
                break;
            }
            indx++;
        }
        
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:indx] animated:YES];
        
    } failure:^(ZNGError *error) {
        [self showAlertForError:error];
    }];
}

- (void)showAlertForError:(ZNGError *)error
{
    [[[UIAlertView alloc] initWithTitle:error.errorText
                                message:error.errorDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
