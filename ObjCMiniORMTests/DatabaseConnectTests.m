//
//  ObjCMiniORMTests.m
//  ObjCMiniORMTests
//
//  Created by Kirmanie Ravariere on 10/2/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "DatabaseConnectTests.h"
#import "MORepository.h"

@implementation DatabaseConnectTests
+(void)tearDown{
    //delete test database
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[MORepository defaultDatabasePath] error:NULL];
}

- (void)testCanOpenDatabase{
    MORepository*repository=[[MORepository alloc]init];
    [repository open];
    BOOL isOpened = [repository sqliteDatabase] != NULL;
    [repository close];
    [repository release];
    STAssertTrue(isOpened, @"can open database");
}

- (void)testCanCloseDatabase{
    MORepository*repository=[[MORepository alloc]init];
    [repository open];
    BOOL wasOpened = [repository sqliteDatabase] != NULL;
    [repository close];
    BOOL isClosed = [repository sqliteDatabase] == NULL;
    [repository release];
    STAssertTrue(wasOpened && isClosed, @"can close database");
}

@end
