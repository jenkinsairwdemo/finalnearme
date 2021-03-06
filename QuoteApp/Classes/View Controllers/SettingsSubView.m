//
//  SettingsSubView.m
//  QuoteApp
//
//  Created by Pavel Vilbik on 6.3.14.
/**
 * Copyright (c) 2014 Kinvey Inc. *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at *
 * http://www.apache.org/licenses/LICENSE-2.0 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License. *
 */

#import "SettingsSubView.h"
#import "SettingTableViewCell.h"

#define TABLE_VIEW_CELL_HEIGHT 44

@interface SettingsSubView () <UITableViewDataSource, SettingTableViewCellDelegate>

@property (strong, nonatomic) NSArray *userData;
@property (nonatomic) BOOL isEditModeTableView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UISwitch *emailConfirmationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *pushNotificationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *pushLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailConfirmationLabel;

@property (nonatomic) BOOL isUserSaving;
@end

@implementation SettingsSubView


#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup{
    
    [[NSBundle mainBundle] loadNibNamed:@"SettingsSubView"
                                  owner:self
                                options:nil];
    
    [self addSubview:self.view];
    self.view.frame = self.bounds;
    self.tableView.dataSource = self;
    self.isEditModeTableView = NO;
    self.titleLabel.text = LOC(TBC_SETTINGS);
    self.pushLabel.text = LOC(SVC_PUSH_LABEL);
    self.emailConfirmationLabel.text = LOC(SVC_EMAIL_CONFIRMATION_LABEL);
    [self.editButton setTitle:LOC(EDIT) forState:UIControlStateNormal];

    self.titleLabel.textColor = BAR_COLOR;
    
    //Setup UI by user attribute value
    self.emailConfirmationSwitch.on = [[[KCSUser activeUser] getValueForAttribute:USER_INFO_KEY_EMAIL_CONFIRMATION_ENABLE] boolValue];
    self.pushNotificationSwitch.on = [[[KCSUser activeUser] getValueForAttribute:USER_INFO_KEY_PUSH_NOTIFICATION_ENABLE] boolValue];
    self.tableView.scrollEnabled = NO;
        
    [self updateUserData];
}


#pragma mark - Setters and Getters

- (void)setUserData:(NSArray *)userData{
    
    _userData = userData;
    
    NSInteger indexAccountNumber = [[self allUserInfoKey] indexOfObject:USER_INFO_KEY_ACCOUNT_NUMBER];
    
    //Extract data from user attribute
    if ([_userData[indexAccountNumber] isEqualToString:@""]) {
        NSMutableArray *userData = [_userData mutableCopy];
        userData[indexAccountNumber] = [KCSUser activeUser].userId;
        _userData = [userData copy];
    }
    
    [self.tableView reloadData];
}


#pragma mark - Actions

- (IBAction)pressEdit:(UIButton *)sender {
    
    KCSUser *user = [KCSUser activeUser];
    
    if (![user.username isEqualToString:@"demoSampleQuote"]) {
        self.isEditModeTableView = self.isEditModeTableView ? NO : YES;
        
        if (self.isEditModeTableView) {
            [self.editButton setTitle:LOC(DONE) forState:UIControlStateNormal];
        }else{
            self.isUserSaving = YES;
            [self endInputIfNeed];
            if ([self isValidEmail:self.userData[4]] || !self.emailConfirmationSwitch.on) {
                [self.editButton setTitle:LOC(EDIT) forState:UIControlStateNormal];
                [self.spinner startAnimating];
                
                
                //Save user info
                [[DataHelper instance] saveUserWithInfo:[self userInfo]
                                              OnSuccess:^(NSArray *users){
                                                  self.isUserSaving = NO;
                                                  if (users.count) {
                                                      [self.spinner stopAnimating];
                                                  }
                                              }
                                              onFailure:^(NSError *error){
                                                  self.isUserSaving = NO;
                                                  [self.spinner stopAnimating];
                                              }];
            }else{
                [self showNotValidEmailMessage];
                self.isEditModeTableView = YES;
            }
            
        }
        
        [self.tableView reloadData];
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Demo Account Limit"
                                                            message:@"You can't change user info in demo account.\n Please sign up new account for testing this function"
                                                           delegate:nil
                                                  cancelButtonTitle:LOC(CANCEL)
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
}

- (IBAction)switchEmailPush {
    
    [self.spinner startAnimating];
    
    //Save user info
    [[DataHelper instance] saveUserWithInfo:[self userInfo]
                                  OnSuccess:^(NSArray *users){
                                      if (users.count) {
                                          [self.spinner stopAnimating];
                                      }
                                  }
                                  onFailure:^(NSError *error){
                                      [self.spinner stopAnimating];
                                  }];
}


#pragma mark - Utils

- (void)endInputIfNeed{
    
    for (int i = 0; i < self.userData.count; i++) {
        SettingTableViewCell *cell = (SettingTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([cell.valueTextField isFirstResponder]) {
            [cell.valueTextField resignFirstResponder];
        }
    }
}

- (NSDictionary *)userInfo{
    
    NSString *value;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *keyArray = [self allUserInfoKey];
    
    for (int i = 0; i < keyArray.count; i++) {
        value = (NSString *)self.userData[i];
        if (![value isEqualToString:@""]) {
            result[keyArray[i]] = value;
        }
    }
    
    if ([self isValidEmail:self.userData[4]] || !self.emailConfirmationSwitch.on) {
        [result setObject:[NSNumber numberWithBool:self.emailConfirmationSwitch.on]
                   forKey:USER_INFO_KEY_EMAIL_CONFIRMATION_ENABLE];
    }else{
        self.emailConfirmationSwitch.on = NO;
        [result setObject:[NSNumber numberWithBool:self.emailConfirmationSwitch.on]
                   forKey:USER_INFO_KEY_EMAIL_CONFIRMATION_ENABLE];
        
        [[[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                    message:LOC(SVC_NOT_VALID_EMAIL_MESSAGE)
                                   delegate:nil
                          cancelButtonTitle:LOC(CANCEL)
                          otherButtonTitles:nil] show];
    }
    
    [result setObject:[NSNumber numberWithBool:self.pushNotificationSwitch.on]
               forKey:USER_INFO_KEY_PUSH_NOTIFICATION_ENABLE];
    
    return [result copy];
}

- (NSArray *)allUserInfoKey{
    return @[USER_INFO_KEY_CONTACT,
             USER_INFO_KEY_COMPANY,
             USER_INFO_KEY_ACCOUNT_NUMBER,
             USER_INFO_KEY_PHONE,
             USER_INFO_KEY_EMAIL
             ];
}

- (void)updateUserData{
    
    //Update data in user attributes
    KCSUser *user = [KCSUser activeUser];
    
    if (user) {
        NSMutableArray *userData = [NSMutableArray array];
        NSArray *keyArray = [self allUserInfoKey];
        
        for (int i = 0; i < keyArray.count; i++) {
            
            if ([user getValueForAttribute:keyArray[i]]) {
                [userData addObject:[user getValueForAttribute:keyArray[i]]];
            }else{
                
                if ([keyArray[i] isEqualToString:USER_INFO_KEY_EMAIL]) {
                    if (user.email) {
                        [userData addObject:user.email];
                    }else{
                        [userData addObject:@""];
                    }
                }else{
                    [userData addObject:@""];
                }
                
            }
            
        }
        
        self.userData = [userData copy];
    }
}


#pragma mark - TABLE VIEW
#pragma mark - Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.userData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    SettingTableViewCell *cell = [[SettingTableViewCell alloc] init];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = [UIView new];
    cell.selectedBackgroundView = [UIView new];

    NSString *key = [self allUserInfoKey][indexPath.row];
    cell.titleLabel.text = [self titleForCellWithKey:key];
    cell.valueTextField.text = [self defaultValueForKey:key];
    NSString *value = (NSString *)self.userData[indexPath.row];
    if (![value isEqualToString:@""]) {
        cell.valueTextField.text = value;
    }
    cell.delegate = self;
    if (self.isEditModeTableView && (indexPath.row != 2)) {
        cell.valueTextField.enabled = YES;
        cell.valueTextField.placeholder = [self placeholderForCellWithKey:[self allUserInfoKey][indexPath.row]];
        cell.valueTextField.borderStyle = UITextBorderStyleRoundedRect;
    }else{
        cell.valueTextField.enabled = NO;
        cell.valueTextField.placeholder = @"";
        cell.valueTextField.borderStyle = UITextBorderStyleNone;
    }
    
    if (indexPath.row == 4) {
        cell.valueTextField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    
    return cell;
}


#pragma mark - Utils

- (NSString *)defaultValueForKey:(NSString *)key{

    if ([key isEqualToString:USER_INFO_KEY_CONTACT]) {
        return @"Blake Brannon";
    }
    if ([key isEqualToString:USER_INFO_KEY_COMPANY]) {
        return @"World Wide Enterprises";
    }
    if ([key isEqualToString:USER_INFO_KEY_ACCOUNT_NUMBER]) {
        return @"";
    }
    if ([key isEqualToString:USER_INFO_KEY_PHONE]) {
        return @"(555)123-4567";
    }
    if ([key isEqualToString:USER_INFO_KEY_EMAIL]) {
        return @"blake.brannon@world-wide-enterprises.com";
    }

    return nil;
}

- (NSString *)titleForCellWithKey:(NSString *)key{
    
    if ([key isEqualToString:USER_INFO_KEY_CONTACT]) {
        return LOC(SVC_CELL_TITLE_CONTACT);
    }
    if ([key isEqualToString:USER_INFO_KEY_COMPANY]) {
        return LOC(SVC_CELL_TITLE_COMPANY);
    }
    if ([key isEqualToString:USER_INFO_KEY_ACCOUNT_NUMBER]) {
        return LOC(SVC_CELL_TITLE_ACCOUNT_NUMBER);
    }
    if ([key isEqualToString:USER_INFO_KEY_PHONE]) {
        return LOC(SVC_CELL_TITLE_PHONE);
    }
    if ([key isEqualToString:USER_INFO_KEY_EMAIL]) {
        return LOC(SVC_CELL_TITLE_EMAIL);
    }
    
    return nil;
}

- (NSString *)placeholderForCellWithKey:(NSString *)key{
    if ([key isEqualToString:USER_INFO_KEY_CONTACT]) {
        return LOC(SVC_CELL_PLACEHOLDER_CONTACT);
    }
    if ([key isEqualToString:USER_INFO_KEY_COMPANY]) {
        return LOC(SVC_CELL_PLACEHOLDER_COMPANY);
    }
    if ([key isEqualToString:USER_INFO_KEY_ACCOUNT_NUMBER]) {
        return @"";
    }
    if ([key isEqualToString:USER_INFO_KEY_PHONE]) {
        return LOC(SVC_CELL_PLACEHOLDER_PHONE);
    }
    if ([key isEqualToString:USER_INFO_KEY_EMAIL]) {
        return LOC(SVC_CELL_PLACEHOLDER_EMAIL);
    }
    
    return nil;
}

- (BOOL)isValidEmail:(NSString *)email{
    
    NSString *emailRegex = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

- (void)showNotValidEmailMessage{
    [[[UIAlertView alloc] initWithTitle:LOC(ERROR)
                                message:LOC(SVC_NOT_VALID_EMAIL_MESSAGE_EDIT)
                               delegate:nil
                      cancelButtonTitle:LOC(CANCEL)
                      otherButtonTitles:nil] show];
}


#pragma mark - SETTING TABLE VIEW CELL
#pragma mark - Delegate

- (void)valueTextFieldDidEndEditingWithValue:(NSString *)value sender:(SettingTableViewCell *)sender{
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSMutableArray *userData = [self.userData mutableCopy];
    if (indexPath.row == 4) {
        if (![self isValidEmail:value] && !self.isUserSaving) {
            [self showNotValidEmailMessage];
        }
    }
    userData[indexPath.row] = value;
    self.userData = [userData copy];
}

@end
