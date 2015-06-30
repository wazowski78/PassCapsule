//
//  PCXMLDocument.m
//  PassCapsule
//
//  Created by 邵建勇 on 15/6/15.
//  Copyright (c) 2015年 John Shaw. All rights reserved.
//

#import "PCDocumentManager.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "DDXML.h"
#import "PCKeyChainCapsule.h"
#import "PCPassword.h"
#import "PCCapsule.h"


@interface PCDocumentManager ()

@end

@implementation PCDocumentManager
+(instancetype)sharedDocumentManager{
    static PCDocumentManager *kManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        kManager = [[self alloc] init];
    });
    return kManager;
}

- (PCDocumentDatabase *)documentDatabase{
    if (!_documentDatabase) {
        _documentDatabase = [PCDocumentDatabase sharedDocumentDatabase];
    }
    return _documentDatabase;
}

- (BOOL)createDocument:(NSString *)documentName WithMasterPassword:(NSString *)masterPassword{
    
    
    
    NSData *randomData = [PCPassword generateSaltOfSize:64];
    NSString *baseKey = [randomData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [PCKeyChainCapsule setString:baseKey forKey:KEYCHAIN_KEY andServiceName:KEYCHAIN_KEY_SERVICE];
    NSLog(@"base64key  =  %@",baseKey);
    
    
    NSString *hashPassword = [PCPassword hashPassword:masterPassword];
    NSLog(@"hashPassword  =  %@",hashPassword);
    NSString *basePassowrd = [[hashPassword dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [PCKeyChainCapsule setString:basePassowrd forKey:KEYCHAIN_PASSWORD andServiceName:KEYCHAIN_PASSWORD_SERVICE];

    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:documentName];
    BOOL fileExists = [fileManager fileExistsAtPath:filePath];
    
    if (fileExists) {
        NSLog(@"file is existed in path = %@",filePath);
        return NO;
    }else{
        DDXMLDocument *capsuleDocument = [self baseTreeWithPassword:masterPassword];
    
        [[capsuleDocument XMLData] writeToFile:filePath atomically:YES];
        [PCDocumentDatabase setDocumentName:documentName];
        return YES;
        
    }
    return NO;

}

- (DDXMLDocument *)baseTreeWithPassword:(NSString *) password{
    DDXMLElement *rootElement = [[DDXMLElement alloc] initWithName:CAPSULE_ROOT];
    //!!!:测试用，把明文放到xml中，release时一定要记得删除这行
    DDXMLElement *masterKeyElement = [[DDXMLElement alloc] initWithName:@"MasterPassword"];
    [masterKeyElement addAttribute:[DDXMLNode attributeWithName:@"id" stringValue:@"0"]];
    [masterKeyElement setStringValue:password];
    [rootElement addChild:masterKeyElement];
    
    DDXMLElement *groupElement =  [DDXMLElement elementWithName:CAPSULE_GROUP];
    [groupElement addAttribute:[DDXMLNode attributeWithName:CAPSULE_GROUP_NAME stringValue:CAPSULE_GROUP_DEFAULT]];
    NSArray *aCapsule = @[[DDXMLElement elementWithName:CAPSULE_ENTRY_TITLE stringValue:@"zhihu"],
                          [DDXMLElement elementWithName:CAPSULE_ENTRY_ACCOUNT stringValue:@"John Shaw"],
                          [DDXMLElement elementWithName:CAPSULE_ENTRY_PASSWORD stringValue:@"fuck cracker"],
                          [DDXMLElement elementWithName:CAPSULE_ENTRY_SITE stringValue:@"www.zhihu.com"],
                          [DDXMLElement elementWithName:CAPSULE_ENTRY_GROUP stringValue:CAPSULE_GROUP_DEFAULT]];
    [groupElement addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY children:aCapsule attributes:nil]];
    
    [rootElement addChild:groupElement];
    
    DDXMLDocument *capsuleDocument = [[DDXMLDocument alloc] initWithXMLString:[rootElement XMLString] options:0 error:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isCreateDatabase"];
    
    self.documentDatabase.document = capsuleDocument;
    self.documentDatabase.isLoadDatabase = YES;
    return capsuleDocument;

}

- (BOOL)readDocument:(NSString *)documentPath withMasterPassword:(NSString *)masterPassword{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:documentPath];
    if (!fileExists) {
        NSLog(@"file not exits");
        return NO;
    }
    if ([masterPassword length] == 0) {
        NSLog(@"password is empty");
        return NO;
    }
    return YES;
}

- (void)parserDocument:(NSData *)xmlData{
    DDXMLDocument *document = nil;
    if (!self.documentDatabase.isLoadDatabase) {
        document = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
        self.documentDatabase.document = document;
        self.documentDatabase.isLoadDatabase = YES;
    } else {
        document = self.documentDatabase.document;
    }
    NSArray *groups = [document nodesForXPath:@"//group" error:nil];
    //遍历group
    for (DDXMLElement *group in groups) {
        PCCapsuleGroup *aGroup = [PCCapsuleGroup new];
        NSString *name = [[group attributeForName:CAPSULE_GROUP_NAME] stringValue];
        aGroup.groupName = name;


        NSArray *entries = [group children];
        //遍历group中的每个entry
        for (DDXMLElement *entry in entries) {
            NSArray *aEntry = [entry children];
            PCCapsule *aCapsule = [PCCapsule new];
            //遍历entry中的每个详细记录
            for (DDXMLNode *e in aEntry) {
                if ([e.name isEqualToString:CAPSULE_ENTRY_TITLE]) {
                    aCapsule.title = e.stringValue;
                }
                if ([e.name isEqualToString:CAPSULE_ENTRY_ACCOUNT]) {
                    aCapsule.account = e.stringValue;
                }
                if ([e.name isEqualToString:CAPSULE_ENTRY_PASSWORD]) {
                    aCapsule.pass = e.stringValue;
                }
                if ([e.name isEqualToString:CAPSULE_ENTRY_SITE]) {
                    aCapsule.site = e.stringValue;
                }
                if ([e.name isEqualToString:CAPSULE_ENTRY_ICON]) {
                    aCapsule.iconName = e.stringValue;
                }
                if ([e.name isEqualToString:CAPSULE_ENTRY_GROUP]) {
                    aCapsule.category = e.stringValue;
                }

            }
            //将entry反序列化到capsule对象后，保存到相关集合中
            [self.documentDatabase.entries addObject:aCapsule];
            [aGroup.groupEntries addObject:aCapsule];
        }
        
        //保存group
        aGroup.groupCount = [aGroup.groupEntries count];
        [self.documentDatabase.groups addObject:aGroup];

    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PARSER_DONE object:nil];
}

- (void)addNewEntry: (PCCapsule *)entry{
    if (self.documentDatabase.document) {
        DDXMLDocument *document = self.documentDatabase.document;
        NSArray *results = [document nodesForXPath:[NSString stringWithFormat:@"//group[@name=\"%@\"]",CAPSULE_GROUP_DEFAULT] error:nil];
        DDXMLElement *groupElement = [results firstObject];
        
        DDXMLElement *newEntry = [DDXMLElement elementWithName:CAPSULE_ENTRY];
        [newEntry addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY_TITLE stringValue:entry.title]];
        [newEntry addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY_ACCOUNT stringValue:entry.account]];
        [newEntry addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY_PASSWORD stringValue:entry.pass]];
        [newEntry addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY_SITE stringValue:entry.site]];
        [newEntry addChild:[DDXMLElement elementWithName:CAPSULE_ENTRY_GROUP stringValue:entry.category]];
        
        [groupElement addChild:newEntry];
        
        [self.documentDatabase.entries addObject:entry];
        PCCapsuleGroup *group = self.documentDatabase.groups[0];
        [group.groupEntries addObject:entry];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PARSER_DONE object:nil];
    }
}

- (void)saveDocument{
    DDXMLElement *root = [self.documentDatabase.document rootElement];

    NSString *path = [PCDocumentDatabase documentPath];
    BOOL wirteSuccess = [[root XMLString] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@" %@ ",[root XMLString]);
    NSLog(@"documentPath = %@",path);
    if (wirteSuccess) {
        NSLog(@"write file success");
    } else {
        NSLog(@"write file fail");
    }



}

//改用 apple security框架中的 SecRandom
//- (void)testDecypyt{
//    NSString *key = [PCKeyChainCapsule stringForKey:@"masterKey" andServiceName:KEYCHAIN_KEY_SERVICE];
//    NSData *decryptData = [RNDecryptor decryptData:self.testEncryptData
//                                      withPassword:key
//                                             error:nil];
//    NSString *decryptString = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
//    NSLog(@"decrypt string is %@",decryptString);
//}
//
//
//NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789~!@#$%^&*()_+`-=[]\\;',./{}|:\"<>?";
//
//- (NSString *) randomStringWithLength: (int)len{
//    
//    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
//    
//    for (int i=0; i<len; i++) {
//        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
//    }
//    
//    return randomString;
//    
////另一种方案
////    char data[NUMBER_OF_CHARS];
////    for (int x=0;x<NUMBER_OF_CHARS;data[x++] = (char)('A' + (arc4random_uniform(26))));
////    return [[NSString alloc] initWithBytes:data length:NUMBER_OF_CHARS encoding:NSUTF8StringEncoding];
////
////
//
////第三种方案
////    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
////    NSString *intervalString = [NSString stringWithFormat:@"%f", today];
////    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[intervalString doubleValue]];
////    
////    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
////    [formatter setDateFormat:@"yyyyMMddhhmm"];
////    NSString *strdate=[formatter stringFromDate:date];
//}


@end
