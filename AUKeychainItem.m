//
//  AUKeychainItem.m
//  KeychainTest
//
//  Created by Aziz Uysal on 10/3/13.
//  Copyright (c) 2013 Aziz Uysal. All rights reserved.
//

#import "AUKeychainItem.h"

NSString *const kKeychainErrorDomain = @"com.azizuysal.auKeychainItem";

@interface AUKeychainItem ()
@property (nonatomic) NSMutableDictionary *query;
@property (nonatomic) NSMutableDictionary *item;
@end

@implementation AUKeychainItem

@synthesize query = _query;

#pragma mark - Public methods

+ (NSArray *)allItemsForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup account:(NSString *)account error:(NSError **)error
{
    NSMutableDictionary *query = [NSMutableDictionary new];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    if (service) [query setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    if (identifier) [query setObject:[identifier dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
#if TARGET_OS_IPHONE
    #if TARGET_IPHONE_SIMULATOR
    if (accessGroup) [query setObject:[[self class] appIdentifierPrefix] forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];
    #else
    if (accessGroup) [query setObject:[NSString stringWithFormat:@"%@.%@", [self appIdentifierPrefix], accessGroup] forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];
    #endif
#endif
    if (account) [query setObject:account forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    
    [query setObject:(__bridge id)(kSecMatchLimitAll) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (status != errSecSuccess && error != NULL)
        *error = [NSError errorWithDomain:kKeychainErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey:@"Error fetching all keychain items"}];
    
    NSMutableArray *items = [NSMutableArray new];
    for (NSMutableDictionary *dict in (__bridge NSArray *)(result))
    {
        [items addObject:[[AUKeychainItem alloc] initWithKeychainDictionary:dict]];
    }
    
    return items;
}

+ (instancetype)itemForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup error:(NSError **)error
{
    return [AUKeychainItem itemForService:service identifier:identifier accessGroup:accessGroup account:nil error:error];
}

+ (instancetype)itemForService:(NSString *)service identifier:(NSString *)identifier accessGroup:(NSString *)accessGroup account:(NSString *)account error:(NSError **)error
{
    AUKeychainItem *item = [AUKeychainItem new];
#if TARGET_OS_IPHONE
    item.accessGroup = accessGroup;
#endif
    item.service = service;
    item.identifier = identifier;
    item.account = account;
    
    OSStatus status = [item fetch];
    if (status != errSecSuccess)
    {
        if (error)
            *error = [NSError errorWithDomain:kKeychainErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey:@"Error fetching keychain item"}];
        if (status != errSecItemNotFound)
            item = nil;
    }
    
    return item;
}

- (NSError *)saveItem
{
    NSError *error = nil;
    
    if (self.item == nil)
        self.item = [NSMutableDictionary dictionaryWithDictionary:self.query];
    
    NSMutableDictionary *updateQuery = [NSMutableDictionary dictionaryWithDictionary:self.query];
    [updateQuery removeObjectForKey:(__bridge id)(kSecClass)];
    [updateQuery setObject:[self.password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecValueData)];
    
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)(self.item), (__bridge CFDictionaryRef)(updateQuery));
    if (status == errSecItemNotFound)
    {
        status = SecItemAdd((__bridge CFDictionaryRef)(self.query), NULL);
        if (status != errSecSuccess)
            error = [NSError errorWithDomain:kKeychainErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey:@"Error creating keychain item"}];
    }
    else if (status != errSecSuccess)
    {
        error = [NSError errorWithDomain:kKeychainErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey:@"Error updating keychain item"}];
    }
    
    return error;
}

- (NSError *)deleteItem
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:self.query];
    
    NSError *error = nil;
    OSStatus status = errSecSuccess;
#if TARGET_OS_IPHONE
    status = SecItemDelete((__bridge CFDictionaryRef)(query));
#else
    CFTypeRef result = NULL;
    [query setObject:@YES forKey:kSecReturnRef];
    status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (status == errSecSuccess)
        status = SecKeychainItemDelete((SecKeychainItemRef)result);
    if (result)
        CFRelease(result);
#endif
    if (status != errSecSuccess)
        error = [NSError errorWithDomain:kKeychainErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey:@"Error deleting keychain item"}];
    else
    {
        self.query = [NSMutableDictionary new];
        self.item = nil;
    }
    
    return error;
}

#pragma mark - Private methods

+ (NSString *)appIdentifierPrefix
{
    static NSString *prefix = nil;
    if (prefix == nil)
    {
        AUKeychainItem *temp = [AUKeychainItem itemForService:@"AUKeychainItemTest" identifier:@"AUKeychainItemTest" accessGroup:nil account:nil error:nil];
        [temp saveItem];
        [temp fetch];
        prefix = [[[temp.accessGroup componentsSeparatedByString:@"."] objectEnumerator] nextObject];
        [temp deleteItem];
    }
    return prefix;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.query = [NSMutableDictionary new];
    }
    return self;
}

- (id)initWithKeychainDictionary:(NSMutableDictionary *)dict
{
    self = [self init];
    if (self)
    {
        self.query = dict;
        self.item = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    return self;
}

- (OSStatus)fetch
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:self.query];
    [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [query setObject:(__bridge id)(kSecMatchLimitOne) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (status == errSecSuccess)
    {
        self.query = (__bridge NSMutableDictionary *)(result);
        self.item = [NSMutableDictionary dictionaryWithDictionary:self.query];
        
        [query removeObjectForKey:(__bridge id)(kSecReturnAttributes)];
        [query setObject:@YES forKey:(__bridge id<NSCopying>)(kSecReturnData)];
        
        result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
        if (status == errSecSuccess)
        {
            [self.query setObject:(__bridge id)(result) forKey:(__bridge id<NSCopying>)(kSecValueData)];
        }
    }
    
    return status;
}

- (NSMutableDictionary *)query
{
    if (_query == nil)
        _query = [NSMutableDictionary new];
    return _query;
}

- (void)setQuery:(NSMutableDictionary *)query
{
    _query = [NSMutableDictionary dictionaryWithDictionary:query];
    [_query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"AUKeychainItem: %@", self.query];
}

#pragma mark - Accessors

#if TARGET_OS_IPHONE
- (NSString *)accessGroup
{
    return [self.query objectForKey:(__bridge id)(kSecAttrAccessGroup)];
}

- (void)setAccessGroup:(NSString *)accessGroup
{
    if (accessGroup)
#if TARGET_IPHONE_SIMULATOR
        [self.query setObject:[[self class] appIdentifierPrefix] forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];
#else
        [self.query setObject:[NSString stringWithFormat:@"%@.%@", [[self class] appIdentifierPrefix], accessGroup] forKey:(__bridge id<NSCopying>)(kSecAttrAccessGroup)];
#endif
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrAccessGroup)];
}
#endif

- (NSString *)service
{
    return [self.query objectForKey:(__bridge id)(kSecAttrService)];
}

- (void)setService:(NSString *)service
{
    if (service)
        [self.query setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrService)];
}

- (NSString *)identifier
{
    return [[NSString alloc] initWithData:[self.query objectForKey:(__bridge id)(kSecAttrGeneric)] encoding:NSUTF8StringEncoding];
}

- (void)setIdentifier:(NSString *)identifier
{
    if (identifier)
        [self.query setObject:[identifier dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrGeneric)];
}

- (NSString *)account
{
    return [self.query objectForKey:(__bridge id)(kSecAttrAccount)];
}

- (void)setAccount:(NSString *)account
{
    if (account)
        [self.query setObject:account forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrAccount)];
}

- (NSString *)password
{
    return [[NSString alloc] initWithData:[self.query objectForKey:(__bridge id)(kSecValueData)] encoding:NSUTF8StringEncoding];
}

- (void)setPassword:(NSString *)password
{
    if (password)
        [self.query setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecValueData)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecValueData)];
}

- (NSString *)label
{
    return [self.query objectForKey:(__bridge id)(kSecAttrLabel)];
}

- (void)setLabel:(NSString *)label
{
    if (label)
        [self.query setObject:label forKey:(__bridge id<NSCopying>)(kSecAttrLabel)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrLabel)];
}

- (NSString *)itemDescription
{
    return [self.query objectForKey:(__bridge id)(kSecAttrDescription)];
}

- (void)setItemDescription:(NSString *)itemDescription
{
    if (itemDescription)
        [self.query setObject:itemDescription forKey:(__bridge id<NSCopying>)(kSecAttrDescription)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrDescription)];
}

- (NSString *)comment
{
    return [self.query objectForKey:(__bridge id)(kSecAttrComment)];
}

- (void)setComment:(NSString *)comment
{
    if (comment)
        [self.query setObject:comment forKey:(__bridge id<NSCopying>)(kSecAttrComment)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrComment)];
}

- (NSNumber *)creator
{
    return [self.query objectForKey:(__bridge id)(kSecAttrCreator)];
}

- (void)setCreator:(NSNumber *)creator
{
    if (creator)
        [self.query setObject:creator forKey:(__bridge id<NSCopying>)(kSecAttrCreator)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrCreator)];
}

- (NSNumber *)type
{
    return [self.query objectForKey:(__bridge id)(kSecAttrType)];
}

- (void)setType:(NSNumber *)type
{
    if (type)
        [self.query setObject:type forKey:(__bridge id<NSCopying>)(kSecAttrType)];
    else
        [self.query removeObjectForKey:(__bridge id)(kSecAttrType)];
}

- (BOOL)isInvisible
{
    id value = [self.query objectForKey:(__bridge id)(kSecAttrIsInvisible)];
    if (value)
        return CFBooleanGetValue((__bridge CFBooleanRef)(value));
    return NO;
}

- (void)setInvisible:(BOOL)invisible
{
    [self.query setObject:(__bridge id)(invisible ? kCFBooleanTrue : kCFBooleanFalse) forKey:(__bridge id<NSCopying>)(kSecAttrIsInvisible)];
}

- (BOOL)isNegative
{
    id value = [self.query objectForKey:(__bridge id)(kSecAttrIsNegative)];
    if (value)
        return CFBooleanGetValue((__bridge CFBooleanRef)(value));
    return NO;
}

- (void)setNegative:(BOOL)negative
{
    [self.query setObject:(__bridge id)(negative ? kCFBooleanTrue : kCFBooleanFalse) forKey:(__bridge id<NSCopying>)(kSecAttrIsNegative)];
}

- (NSDate *)creationDate
{
    return [self.query objectForKey:(__bridge id)(kSecAttrCreationDate)];
}

- (NSDate *)modificationDate
{
    return [self.query objectForKey:(__bridge id)(kSecAttrModificationDate)];
}

#if TARGET_OS_IPHONE
- (AccessibilityType)accessible
{
    CFTypeRef accessibilityType = (__bridge CFTypeRef)([self.query objectForKey:(__bridge id)(kSecAttrAccessible)]);
    
    AccessibilityType result = unspecified;
    if (accessibilityType == kSecAttrAccessibleWhenUnlocked)
        result = accessibleWhenUnlocked;
    else if (accessibilityType == kSecAttrAccessibleAfterFirstUnlock)
        result = accessibleAfterFirstUnlock;
    else if (accessibilityType == kSecAttrAccessibleAlways)
        result = accessibleAlways;
    else if (accessibilityType == kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        result = accessibleWhenUnlockedThisDeviceOnly;
    else if (accessibilityType == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        result = accessibleAfterFirstUnlockThisDeviceOnly;
    else if (accessibilityType == kSecAttrAccessibleAlwaysThisDeviceOnly)
        result = accessibleAlwaysThisDeviceOnly;
    
    return result;
}

- (void)setAccessible:(AccessibilityType)accessible
{
    if (accessible == unspecified)
        [self.query removeObjectForKey:(__bridge id)(kSecAttrAccessible)];
    else if (accessible == accessibleWhenUnlocked)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    else if (accessible == accessibleAfterFirstUnlock)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    else if (accessible == accessibleAlways)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleAlways) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    else if (accessible == accessibleWhenUnlockedThisDeviceOnly)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleWhenUnlockedThisDeviceOnly) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    else if (accessible == accessibleAfterFirstUnlockThisDeviceOnly)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    else if (accessible == accessibleAlwaysThisDeviceOnly)
        [self.query setObject:(__bridge id)(kSecAttrAccessibleAlwaysThisDeviceOnly) forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
}
#endif

@end
