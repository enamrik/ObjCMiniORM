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
-(void)tearDown{
    //delete test database
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[MORepository defaultDatabasePath] error:NULL];
    
     NSString* expectedPath =[[self documentsPath] stringByAppendingPathComponent:@"data.db"];
    [fileManager removeItemAtPath:expectedPath error:NULL];
     expectedPath =[[self documentsPath] stringByAppendingPathComponent:@"test.db"];
    [fileManager removeItemAtPath:expectedPath error:NULL];
    expectedPath =[[self libraryPath] stringByAppendingPathComponent:@"test.db"];
    [fileManager removeItemAtPath:expectedPath error:NULL];
}

- (void)testCanOpenDatabase{
    MORepository*repository=[[MORepository alloc]init];
    [repository open];
    BOOL isOpened = [repository sqliteDatabase] != NULL;
    [repository close];
    STAssertTrue(isOpened, @"can open database");
}

- (void)testCanCloseDatabase{
    MORepository*repository=[[MORepository alloc]init];
    [repository open];
    BOOL wasOpened = [repository sqliteDatabase] != NULL;
    [repository close];
    BOOL isClosed = [repository sqliteDatabase] == NULL;
    STAssertTrue(wasOpened && isClosed, @"can close database");
}

-(void)testWillUseBundleFile{
    NSString* expectedPath =[[self libraryPath] stringByAppendingPathComponent:@"test.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:expectedPath error:NULL];
    
    MORepository*repository=[[MORepository alloc]initWithBundleFile:@"test.db"];
    [repository open];
       BOOL tableExists =[[repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?;"
            withParameters:[NSArray arrayWithObject:@"test"]] intValue] > 0;
    [repository close];
    
    STAssertTrue(tableExists && [[NSFileManager defaultManager]fileExistsAtPath:expectedPath],
        @"Will Use Bundle File");
}

-(void)testWillCreateDefaultDatabase{
    NSString* expectedPath =[[self libraryPath] stringByAppendingPathComponent:@"data.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:expectedPath error:NULL];
    
    MORepository*repository=[[MORepository alloc]init];
    [repository open];
    [repository close];
    
    STAssertTrue([[NSFileManager defaultManager]fileExistsAtPath:expectedPath],
        @"Will Create Default Database");
}

-(void)testWillUseSpecifiedPath{
    NSString* expectedPath =[[self documentsPath] stringByAppendingPathComponent:@"data.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:expectedPath error:NULL];
    
    MORepository*repository=[[MORepository alloc]initWithDBFilePath:expectedPath];
    [repository open];
    [repository close];
    
    STAssertTrue([[NSFileManager defaultManager]fileExistsAtPath:expectedPath], @"Will Create Default Database");
}

-(void)testWillUseBundleFileAndSpecifiedPath{
    NSString* expectedPath =[[self documentsPath] stringByAppendingPathComponent:@"data.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:expectedPath error:NULL];
    
    MORepository*repository=[[MORepository alloc]initWithBundleFile:@"test.db" dbFilePath:expectedPath];
    [repository open];
       BOOL tableExists =[[repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?;"
            withParameters:[NSArray arrayWithObject:@"test"]] intValue] > 0;
    [repository close];
    
    STAssertTrue(tableExists && [[NSFileManager defaultManager]fileExistsAtPath:expectedPath],
        @"Will Create Default Database");
}

-(NSString*)libraryPath{
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	return [documentPaths objectAtIndex:0];
}

-(NSString*)documentsPath{
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [documentPaths objectAtIndex:0];
}

@end
