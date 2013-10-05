//
//  KeychainTestTests.m
//  KeychainTestTests
//
//  Created by Aziz Uysal on 10/3/13.
//  Copyright (c) 2013 Aziz Uysal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AUKeychainItem.h"

NSString * const kTestService = @"testService";
NSString * const kTestIdentifier = @"testIdentifier";
NSString * const kTestAccessGroup = @"com.azizuysal.keychainGroup";
NSString * const kTestAccount = @"testAccount";
NSString * const kTestAccount2 = @"testAccount2";
NSString * const kTestPassword = @"testPassword";
NSString * const kTestPassword2 = @"testPassword2";
NSString * const kTestLabel = @"testLabel";
NSString * const kTestLabel2 = @"testLabel2";
NSString * const kTestComment = @"testComment";
NSString * const kTestDescription = @"testDescription";
uint const kTestCreator = 'aZiz';
uint const kTestType = 'tYpe';
BOOL const kTestInvisible = NO;
BOOL const kTestNegative = NO;
AccessibilityType const kTestAccessible = accessibleAfterFirstUnlock;

@interface KeychainTestTests : XCTestCase

@end

@implementation KeychainTestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAUKeychainItem
{
    NSError *error = nil;
    NSArray *items = [AUKeychainItem allItemsForService:nil identifier:nil accessGroup:nil account:nil error:&error];
    XCTAssertTrue(error == nil || error.code == errSecItemNotFound, @"Retrieving all keychain items generated error: %@" ,error);
    
    for (AUKeychainItem *item in items)
    {
        error = [item deleteItem];
        XCTAssertTrue(error == nil, @"Deleting all keychain items generated error: %@" ,error);
    }
    
    AUKeychainItem *item = [AUKeychainItem itemForService:kTestService identifier:kTestIdentifier accessGroup:kTestAccessGroup error:&error];
    XCTAssertTrue(error == nil || error.code == errSecItemNotFound, @"Initializing keychain item generated error: %@" ,error);
    
    item.account = kTestAccount;
    item.password = kTestPassword;
    item.label = kTestLabel;
    item.comment = kTestComment;
    item.itemDescription = kTestDescription;
    item.creator = [NSNumber numberWithUnsignedInt:kTestCreator];
    item.type = [NSNumber numberWithUnsignedInt:kTestType];
    item.invisible = kTestInvisible;
    item.negative = kTestNegative;
    
    NSDate *saveDate = [NSDate date];
    error = [item saveItem];
    XCTAssertTrue(error == nil, @"Saving keychain item generated error: %@" ,error);
    
    item = [AUKeychainItem itemForService:kTestService identifier:kTestIdentifier accessGroup:kTestAccessGroup error:&error];
    XCTAssertTrue(error == nil, @"Retrieving keychain item generated error: %@" ,error);
    
    XCTAssertTrue([item.creationDate laterDate:saveDate] == item.creationDate, @"Keychain item creation date is wrong: %@", item.creationDate);
    XCTAssertEqualObjects(item.creationDate, item.modificationDate, @"Keychain item creation and modification dates are different.");
    XCTAssertEqualObjects(item.account, kTestAccount, @"Account information is invalid.");
    XCTAssertEqualObjects(item.password, kTestPassword, @"Password information is invalid.");
    XCTAssertEqualObjects(item.label, kTestLabel, @"Label information is invalid.");
    XCTAssertEqualObjects(item.comment, kTestComment, @"Comment information is invalid.");
    XCTAssertEqualObjects(item.itemDescription, kTestDescription, @"Description information is invalid.");
    XCTAssertTrue(item.creator = [NSNumber numberWithUnsignedInt:kTestCreator], @"Creator information is invalid.");
    XCTAssertTrue(item.type = [NSNumber numberWithUnsignedInt:kTestType], @"Type information is invalid.");
    XCTAssertEqual(item.isInvisible, kTestInvisible, @"IsInvisible information is invalid.");
    XCTAssertEqual(item.isNegative, kTestNegative, @"IsNegative information is invalid.");
    
    item.account = kTestAccount2;
    item.password = kTestPassword2;
    item.label = kTestLabel2;
    error = [item saveItem];
    XCTAssertTrue(error == nil, @"Updating keychain item generated error: %@" ,error);
    
    item = [AUKeychainItem itemForService:kTestService identifier:kTestIdentifier accessGroup:kTestAccessGroup error:&error];
    XCTAssertTrue(error == nil, @"Retrieving keychain item a second time generated error: %@" ,error);
    
    XCTAssertNotEqual(item.creationDate, item.modificationDate, @"Keychain item creation and modification dates are same.");
    XCTAssertEqualObjects(item.account, kTestAccount2, @"Account information is not updated.");
    XCTAssertEqualObjects(item.password, kTestPassword2, @"Password information is not updated.");
    XCTAssertEqualObjects(item.label, kTestLabel2, @"Label information is not updated.");
    
    item.accessible = kTestAccessible;
    error = [item saveItem];
    XCTAssertTrue(error == nil, @"Updating keychain item a second time generated error: %@" ,error);
    
    item = [AUKeychainItem itemForService:kTestService identifier:kTestIdentifier accessGroup:kTestAccessGroup error:&error];
    XCTAssertTrue(error == nil, @"Retrieving keychain item a third time generated error: %@" ,error);
    
#if !(TARGET_IPHONE_SIMULATOR)
    XCTAssertEqual(item.accessible, kTestAccessible, @"Accessible information is invalid.");
#endif
    
    error = [item deleteItem];
    XCTAssertTrue(error == nil, @"Deleting keychain item generated error: %@" ,error);
    
    item = [AUKeychainItem itemForService:kTestService identifier:kTestIdentifier accessGroup:kTestAccessGroup error:&error];
    XCTAssertTrue(error.code == errSecItemNotFound, @"Retrieved keychain item that was supposed to be deleted.");
}

@end
