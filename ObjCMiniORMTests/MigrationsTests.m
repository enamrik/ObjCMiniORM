//
//  MigrationsTests.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/5/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "MigrationsTests.h"
#import "MODbMigrator.h"
#import "MORepository.h"
#import "TestScriptFile.h"
#import "MODbModelMeta.h"
#import "TestModel.h"

@implementation MigrationsTests

- (void)setUp{
    //delete test database
    NSFileManager *fileManager = [NSFileManager defaultManager];
     MORepository *repository=[[[MORepository alloc]init]autorelease];
    [fileManager removeItemAtPath:repository.filePathName error:NULL];
}

-(void)testCreateScriptTableIfNotExists{
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    [[[MODbMigrator alloc]initWithRepo:repository andMeta:nil]autorelease];
    
     BOOL check =[[repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?;"
            withParameters:[NSArray arrayWithObject:[MODbMigrator migrationTableName]]] intValue] > 0;
    
     STAssertTrue(check,@"createScriptTableIfNotExists");
}

-(void)testWillRegisterScriptsAndOrderThem{
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:nil]autorelease];
    
    id<IScriptFile>script=[[[TestScriptFile alloc]initWithTimestamp:88 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    script=[[[TestScriptFile alloc]initWithTimestamp:99 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    script=[[[TestScriptFile alloc]initWithTimestamp:100 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    
    [migrator performSelector:@selector(orderScriptFiles)];
    
     STAssertTrue([[migrator registeredScriptFiles] count] > 0,
        @"willRegisterScriptsAndOrderThem  -  will register");
    STAssertTrue([[[migrator registeredScriptFiles] objectAtIndex:0] timestamp] == 100,
        @"willRegisterScriptsAndOrderThem  -  will order");
}

-(void)testGetAllScriptsThatHaventRun{
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:nil]autorelease];
    
    [migrator performSelector:@selector(checkCreateScriptTable)];
    
    [repository executeSQL:[NSString stringWithFormat:@"insert into %@(timestamp, runOn) values(88, 88)",
        [MODbMigrator migrationTableName]] withParameters:nil];
    
    [repository executeSQL:[NSString stringWithFormat:@"insert into %@(timestamp, runOn) values(99, 99)",
        [MODbMigrator migrationTableName]] withParameters:nil];
    
    id<IScriptFile>script=[[[TestScriptFile alloc]initWithTimestamp:88 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    script=[[[TestScriptFile alloc]initWithTimestamp:99 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    script=[[[TestScriptFile alloc]initWithTimestamp:100 andSql:@"sql"] autorelease];
    [migrator registerScriptFile:script];
    
    NSArray* haventRun = [migrator performSelector:@selector(getScriptFilesThatHaventBeenRun)];
    STAssertTrue([haventRun count] == 1,@"getAllScriptsThatHaventBeenRun - verify count");
    STAssertTrue([[haventRun objectAtIndex:0] timestamp] == 100, 
        @"getAllScriptsThatHaventBeenRun - verify file");
}

-(void)testWillGetTableNames{
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:nil]autorelease];
    NSArray* tablesSchema = [migrator performSelector:@selector(getTableDbMeta)];
    
    STAssertTrue([tablesSchema count] > 0,@"testWillGetTableNames - has tables");

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",[MODbMigrator migrationTableName]];
    NSArray *results = [tablesSchema filteredArrayUsingPredicate:predicate];

    STAssertTrue([results count] > 0,@"testWillGetTableNames - has script table");
}

-(void)testWillGetColumnDataForTable{
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:nil]autorelease];
    NSArray* columnSchema = [migrator performSelector:@selector(getColumnDbMetaForTable:)
        withObject:[MODbMigrator migrationTableName]];
    
    STAssertTrue([columnSchema count] > 0,@"testWillGetColumnDataForTable - has columns");

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == 'timestamp'"];
    NSArray *results = [columnSchema filteredArrayUsingPredicate:predicate];

    STAssertTrue([results count] > 0,@"testWillGetColumnDataForTable - has timestamp column");
}

-(void)testCreateTableForModelIfNotInDb{
    MODbModelMeta *meta=[[[MODbModelMeta alloc]init]autorelease];
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:meta]autorelease];
    
    [meta modelAddByName:@"TestTable"];
    [meta propertyAdd:@"TestTableId"];
    [meta propertySetIsKey:true];
    [meta propertyAdd:@"TableName"];
    [meta propertySetType:@"NSString"];
    [meta modelAddByType:TestModel.class];
    
    BOOL allOkay = [migrator updateDatabaseAndRunScripts:true];
     STAssertTrue(allOkay,@"CreateTableForModelIfNotInDb - sql did run");
    
    [repository executeSQL:@"insert into TestTable(TableName) values('MyTable')" withParameters:nil];
    NSArray* records =[repository query:@"select * from TestTable" withParameters:nil];
    STAssertTrue([records count] == 1,@"testWillGetColumnDataForTable - has timestamp column");
    
}

-(void)testAddColumnsToExistingTable{
    MODbModelMeta *meta=[[[MODbModelMeta alloc]init]autorelease];
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:meta]autorelease];
    
    [repository executeSQL:@"create table MyTable(TestTableId INTEGER PRIMARY KEY)" withParameters:nil];
    
    [meta modelAddByName:@"TestTable"];
    [meta modelSetTableName:@"MyTable"];
    [meta propertyAdd:@"Id"];
    [meta propertySetIsKey:true];
    [meta propertyAdd:@"TableName"];
    [meta propertySetType:@"NSString"];
    
    BOOL allOkay = [migrator updateDatabaseAndRunScripts:true];
     STAssertTrue(allOkay,@"AddColumnsToExistingTable - sql did run");
    
     BOOL check =[[repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='TestTable';"
            withParameters:nil] intValue] == 0;
    STAssertTrue(check,@"AddColumnsToExistingTable");
    
    [repository executeSQL:@"insert into MyTable(TableName) values('MyTable')" withParameters:nil];
    NSArray* records =[repository query:@"select * from MyTable" withParameters:nil];
    STAssertTrue([records count] == 1,@"AddColumnsToExistingTable");
}

-(void)testSetupManualBindings{
    MODbModelMeta *meta=[[[MODbModelMeta alloc]init]autorelease];
    MORepository *repository=[[[MORepository alloc]init]autorelease];
    MODbMigrator *migrator = [[[MODbMigrator alloc]initWithRepo:repository andMeta:meta]autorelease];
    
    [meta modelAddByName:@"TestTable"];
    [meta modelSetTableName:@"MyTable"];
    [meta propertyAdd:@"keyProperty"];
    [meta propertySetColumnName:@"Id"];
    [meta propertySetIsKey:true];
    [meta propertyAdd:@"secondProperty"];
    [meta propertySetColumnName:@"TableName"];
    [meta propertySetType:@"NSString"];
    
    BOOL allOkay = [migrator updateDatabaseAndRunScripts:true];
     STAssertTrue(allOkay,@"AddColumnsToExistingTable - sql did run");
    
     BOOL check =[[repository
            executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='TestTable';"
            withParameters:nil] intValue] == 0;
    STAssertTrue(check,@"AddColumnsToExistingTable");
    
    [repository executeSQL:@"insert into MyTable(TableName) values('MyTable')" withParameters:nil];
    NSArray* records =[repository query:@"select Id,TableName from MyTable" withParameters:nil];
    STAssertTrue([records count] == 1,@"AddColumnsToExistingTable");
}

@end
