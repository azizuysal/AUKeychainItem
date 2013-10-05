//
//  AUKeychainItem.h
//  KeychainTest
//
//  Created by Aziz Uysal on 10/3/13.
//  Copyright (c) 2013 Aziz Uysal. All rights reserved.
//

#import <Foundation/Foundation.h>

//kSecAttrAccessible
//kSecAttrAccessGroup
//kSecAttrCreationDate
//kSecAttrModificationDate
//kSecAttrDescription
//kSecAttrComment
//kSecAttrCreator
//kSecAttrType
//kSecAttrLabel
//kSecAttrIsInvisible
//kSecAttrIsNegative
//kSecAttrAccount
//kSecAttrService
//kSecAttrGeneric

#if TARGET_OS_IPHONE
typedef enum
{
    unspecified,
    accessibleWhenUnlocked,                     // kSecAttrAccessibleWhenUnlocked
    accessibleAfterFirstUnlock,                 // kSecAttrAccessibleAfterFirstUnlock
    accessibleAlways,                           // kSecAttrAccessibleAlways
    accessibleWhenUnlockedThisDeviceOnly,       // kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    accessibleAfterFirstUnlockThisDeviceOnly,   // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    accessibleAlwaysThisDeviceOnly,             // kSecAttrAccessibleAlwaysThisDeviceOnly
} AccessibilityType;
#endif

@interface AUKeychainItem : NSObject

#if TARGET_OS_IPHONE
@property (nonatomic) NSString *accessGroup;
@property (nonatomic) AccessibilityType accessible;
#endif
@property (nonatomic) NSString *service;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *account;
@property (nonatomic) NSString *password;

@property (nonatomic) NSString *label;
@property (nonatomic) NSString *itemDescription;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSNumber *creator;
@property (nonatomic) NSNumber *type;
@property (nonatomic, getter = isInvisible) BOOL invisible;
@property (nonatomic, getter = isNegative) BOOL negative;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSDate *modificationDate;

- (NSError *)saveItem;
- (NSError *)deleteItem;

+ (instancetype)itemForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup error:(NSError **)error;
+ (instancetype)itemForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup account:(NSString *)account error:(NSError **)error;

+ (NSArray *)allItemsForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup account:(NSString *)account error:(NSError **)error;

@end
