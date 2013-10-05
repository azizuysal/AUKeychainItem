//
//  MainViewController.m
//  KeychainTest
//
//  Created by Aziz Uysal on 10/3/13.
//  Copyright (c) 2013 Aziz Uysal. All rights reserved.
//

#import "MainViewController.h"
#import "AUKeychainItem.h"

NSString * const kKeychainService = @"http://www.azizuysal.com";
//NSString * const kKeychainIdentifier = @"randomIdentifierString";
//NSString * const kKeychainGroup = @"com.azizuysal.KeychainGroup";

@interface MainViewController ()
{
@private
    __weak IBOutlet UITextField *_usernameField;
    __weak IBOutlet UITextField *_passwordField;
    __weak IBOutlet UITextView *_logView;
}
- (IBAction)didClickSave:(id)sender;
- (IBAction)didClickDelete:(id)sender;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _logView.layer.borderColor = [UIColor grayColor].CGColor;
    _logView.layer.borderWidth = 0.5;
    _logView.layer.cornerRadius = 8;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    NSArray *items = [AUKeychainItem allItemsForService:nil identifier:nil accessGroup:nil account:nil error:nil];
    if (items.count > 0)
    {
        NSMutableString *logString = [NSMutableString stringWithFormat:@"Found %lu existing item%@:", (unsigned long)items.count, items.count > 1 ? @"s" : @""];
        for (int i = 0; i < items.count; i++)
        {
            [logString appendFormat:@"\nItem[%d]: %@", i, items[i]];
            [items[0] deleteItem];
        }
        [self log:logString];
    }
    
    AUKeychainItem *item = [AUKeychainItem itemForService:kKeychainService identifier:nil accessGroup:nil error:nil];
    _usernameField.text = item.account;
    _passwordField.text = item.password;
    
    [self log:@"Retrieved username:%@ - password:%@", _usernameField.text, _passwordField.text];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    AUKeychainItem *item = [AUKeychainItem itemForService:kKeychainService identifier:nil accessGroup:nil error:nil];
    _usernameField.text = item.account;
    _passwordField.text = item.password;
    
    [self log:@"Retrieved username:%@ - password:%@", _usernameField.text, _passwordField.text];
}

- (IBAction)didClickSave:(id)sender
{
    AUKeychainItem *item = [AUKeychainItem itemForService:kKeychainService identifier:nil accessGroup:nil error:nil];
    item.account = _usernameField.text;
    item.password = _passwordField.text;
    [item saveItem];
    
    [self log:@"Saved username:%@ - password:%@", _usernameField.text, _passwordField.text];
}

- (IBAction)didClickDelete:(id)sender
{
    AUKeychainItem *item = [AUKeychainItem itemForService:kKeychainService identifier:nil accessGroup:nil error:nil];
    [item deleteItem];
    
    _usernameField.text = @"";
    _passwordField.text = @"";
    [self log:@"Deleted keychain item."];
}

- (void)log:(NSString *)formatString, ...
{
    NSString *text = nil;
    va_list args;
    va_start(args, formatString);
    text = [[NSString alloc] initWithFormat:formatString arguments:args];
    va_end(args);
    
    if (_logView.text.length > 0)
        _logView.text = [NSString stringWithFormat:@"%@\n\n%@", _logView.text, text];
    else
        _logView.text = text;
    
    [_logView scrollRangeToVisible:NSMakeRange(_logView.text.length, 1)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
