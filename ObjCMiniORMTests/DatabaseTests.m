//
//  DatabaseTests.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/4/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "DatabaseTests.h"
#import "MORepository.h"
#import "TestModel.h"

@implementation DatabaseTests

static MORepository* _repository = nil;

+ (void)setUp{
    //delete test database
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:_repository.filePathName error:NULL];
    
    _repository=[[MORepository alloc]init];
    [_repository open];
    [_repository executeSQL:
        @"create table testmodel(testmodelid integer primary key, fullName text, modelDate number)"
        withParameters:nil];
}

+(void)tearDown{
    [_repository close];
    [_repository release];
}

- (void)setUp{
    [super setUp];
    [_repository beginDeferredTransaction];
}

- (void)tearDown{
    [_repository rollback];
    [super tearDown];
}

-(void)testCommitPropertyTypes{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModel";
    model.modelDate = [NSDate dateWithTimeIntervalSince1970:1000];
    [_repository insert:model];
    
    TestModel* queryModel = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertTrue([model.fullName isEqualToString:queryModel.fullName],
        @"CommitPropertyTypes - string property commited");
    STAssertTrue([model.modelDate isEqualToDate:queryModel.modelDate],
        @"CommitPropertyTypes - date property commited");
}

-(void)testWillInsertObject{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModel";
    [_repository insert:model];

    STAssertTrue(model.testModelId > 0, @"WillInsertObject - will set current object pk property");
    
    TestModel* queryModel = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertTrue(queryModel.testModelId > 0, @"WillInsertObject - can query new object");
}

-(void)testWillUpdateObject{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    [_repository insert:model];
 
    model = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    model.fullName = @"theNewModelName";
    [_repository update:model];
    
    TestModel* queryModel = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertTrue([queryModel.fullName isEqualToString:model.fullName], @"Will Update Object");
}

-(void)testWillDeleteObject{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    [_repository insert:model];
 
    model = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    [_repository delete:model];
    
    NSArray* results = [_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class];
    
    STAssertTrue([results count]==0, @"Will Delete Object");
}

-(void)testWillCommitUpdateObject{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    [_repository insert:model];
 
    model = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    model.fullName = @"theNewModelName";
    [_repository commit:model];
    
    NSArray* results = [_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class];
    STAssertTrue([results count]==1, @"Will Commit Insert Object");
    
    TestModel* queryModel = [results objectAtIndex:0];
    STAssertTrue([queryModel.fullName isEqualToString:model.fullName], @"Will Update Object");
}

-(void)testWillCommitInsertObject{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    NSArray* results = [_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class];
    
    STAssertTrue([results count]==1, @"Will Commit Insert Object");
}

-(void)testWillLoadReadOnlyProperties{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository
        query:@"select *, 5 as readonlyProperty from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertTrue([queryModel.ro_readonlyProperty isEqualToString:@"5"], @"Will Load ReadOnly Properties");
}

-(void)testWillIgnoreNAProperties{
    TestModel *model = [[[TestModel alloc]init]autorelease];
    model.fullName=@"theModelName";
    model.na_ignoreProperty =@"5";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertFalse([queryModel.na_ignoreProperty isEqualToString:@"5"], @"Will Ignore NA Properties");
}

@end