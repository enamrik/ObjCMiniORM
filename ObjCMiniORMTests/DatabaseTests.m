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
#import "MODbModelMeta.h"
#import "TestModel2.h"

@interface DatabaseTests()
@property(strong)MODbModelMeta* modelMeta;
@end

@implementation DatabaseTests

static MORepository* _repository = nil;

+ (void)setUp{
    //delete test database
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[_repository getFilePathName] error:NULL];
    
    _repository=[[MORepository alloc]init];
    [_repository open];
    [_repository executeSQL:
        @"create table testmodel(testmodelid integer primary key, fullName text, modelDate number)"
        withParameters:nil];
}

+(void)tearDown{
    [_repository close];
}

- (void)setUp{
    [super setUp];
    self.modelMeta = [[MODbModelMeta alloc]init];
    [self.modelMeta modelAddByType:TestModel.class];
    [self.modelMeta propertySetCurrentByName:@"readonlyProperty"];
    [self.modelMeta propertySetIsReadOnly:true];
    [self.modelMeta propertySetCurrentByName:@"ignoreProperty"];
    [self.modelMeta propertySetIgnore:true];
    [_repository mergeModelMeta:self.modelMeta];
    [_repository beginDeferredTransaction];
}

- (void)tearDown{
    [_repository rollback];
    [super tearDown];
}

-(void)testCommitPropertyTypes{
    TestModel *model = [[TestModel alloc]init];
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
    TestModel *model = [[TestModel alloc]init];
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
    TestModel *model = [[TestModel alloc]init];
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
    TestModel *model = [[TestModel alloc]init];
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
    TestModel *model = [[TestModel alloc]init];
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
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    NSArray* results = [_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class];
    
    STAssertTrue([results count]==1, @"Will Commit Insert Object");
}

-(void)testWillLoadReadOnlyProperties{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository
        query:@"select *, 5 as readonlyProperty from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertTrue([queryModel.readonlyProperty isEqualToString:@"5"], @"Will Load ReadOnly Properties");
}

-(void)testWillIgnoreProperties{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    model.ignoreProperty =@"5";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository
        query:@"select * from TestModel where testModelId = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModelId]]
        forType:TestModel.class] objectAtIndex:0];
    
    STAssertFalse([queryModel.ignoreProperty isEqualToString:@"5"], @"Will Ignore NA Properties");
}

-(void)testWillWorkWithInternalModelMeta{
    TestModel2 *model = [[TestModel2 alloc]init];
    model.fullName=@"theModelName";

    MORepository * repository = [[MORepository alloc]init];
    [repository open];
    [repository beginDeferredTransaction];
    
    [repository executeSQL:
        @"create table testmodel2(testmodel2id integer primary key, fullName text, modelDate number)"
        withParameters:nil];
    
    [repository commit:model];
    
    TestModel2* queryModel = [[repository
        query:@"select * from TestModel2 where testModel2Id = ? "
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:model.testModel2Id]]
        forType:TestModel2.class] objectAtIndex:0];
    
    [repository rollback];
    [repository close];
    
    STAssertTrue(queryModel != nil, @"WillWorkWithInternalModelMeta");
}

-(void)testWillQueryForTypes{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository queryForType:TestModel.class] objectAtIndex:0];
    STAssertTrue([queryModel.fullName isEqualToString:@"theModelName"], @"Will Query For Types");
}

-(void)testWillQueryForTypesWithWhereClause{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [[_repository queryForType:TestModel.class whereClause:@"testModelId=?"
    withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:1]]] objectAtIndex:0];
    STAssertTrue([queryModel.fullName isEqualToString:@"theModelName"], @"Will Query For Types With Where Clause");
}

-(void)testWillQuerySingleForTypesWithWhereClause{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [_repository querySingleForType:TestModel.class whereClause:@"testModelId=?"
    withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:1]]];
    STAssertTrue([queryModel.fullName isEqualToString:@"theModelName"], @"Will Query For Types With Where Clause");
}

-(void)testWillQueryForTypesWithKey{
    TestModel *model = [[TestModel alloc]init];
    model.fullName=@"theModelName";
    [_repository commit:model];
 
    TestModel* queryModel = [_repository queryForType:TestModel.class key:1];
    STAssertTrue([queryModel.fullName isEqualToString:@"theModelName"], @"Will Query For Types With Key");
}

@end
