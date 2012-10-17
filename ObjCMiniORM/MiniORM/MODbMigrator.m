//
//  MODbMigrator.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/6/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "MODbMigrator.h"
#import "MORepository.h"
#import "MODbModelMeta.h"


@interface MOScriptFile : NSObject<IScriptFile>
@property double fileTimestamp;
@property (copy) NSString*fileSql;
-(double)timestamp;
-(NSString*)sql;
-(BOOL)runBeforeModelUpdate;
@end
@implementation MOScriptFile
@synthesize fileTimestamp,fileSql;
-(void)dealloc{
    self.fileSql=nil;
    [super dealloc];
}
-(double)timestamp{return self.fileTimestamp;}
-(NSString*)sql{return self.fileSql;}
-(BOOL)runBeforeModelUpdate{ return false;}
@end

@interface MODbMigrator()
@property(strong)MORepository*repository;
@property(strong)NSMutableArray* scriptFiles;
@property(strong)MODbModelMeta *modelMeta;
@end

@implementation MODbMigrator

@synthesize repository,scriptFiles,runBeforeScripts,modelScripts,runAfterScripts,
modelMeta;

-(void)dealloc{
    self.runAfterScripts=nil;
    self.modelScripts=nil;
    self.runBeforeScripts=nil;
    self.modelMeta=nil;
    self.scriptFiles=nil;
    self.repository=nil;
    [super dealloc];
}

-(id)initWithRepo:(MORepository*)repo andMeta:(MODbModelMeta*)meta{
    self=[super init];
    if (self) {
        self.modelMeta=meta;
        self.repository=repo;
        [self checkCreateScriptTable];
        self.scriptFiles = [NSMutableArray array];
    }
    return self;
}

-(NSArray*)registeredScriptFiles{
    return self.scriptFiles;
}

+(NSString*)migrationTableName{
    return @"_migrateHistory";
}

-(BOOL)updateDatabaseAndRunScripts:(BOOL)runScripts{
    
    if([self.repository isOpened] == false){
        [NSException raise:@"OpenedRepositoryRequired" format:@"Migrator requires an opened repository"];
    }
    
    NSArray* scriptsToRun = [self getScriptFilesThatHaventBeenRun];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"runBeforeModelUpdate == YES"];
    self.runBeforeScripts = [scriptsToRun filteredArrayUsingPredicate:predicate];
    
    predicate = [NSPredicate predicateWithFormat:@"runBeforeModelUpdate == NO"];
    self.runAfterScripts = [scriptsToRun filteredArrayUsingPredicate:predicate];
    
    self.modelScripts = [self generateModelUpdateScripts];
    
    if(runScripts){
        [self.repository beginDeferredTransaction];
        
        BOOL allOkay = [self runUpdateBeforeScripts:self.runBeforeScripts
            modelScripts:self.modelScripts
            afterScripts:self.runAfterScripts];
        
        if (!allOkay) {
            [self.repository rollback];
            return NO;
        }
        [self.repository commitTransaction];
    }
    return  YES;
}

-(NSArray*)generateModelUpdateScripts{
    int totalModels = [self.modelMeta modelCount];
    NSArray*tables = [self getTableDbMeta];
    NSMutableArray* sqlScripts = [NSMutableArray array];
    
    for(int modelIndex = 0; modelIndex < totalModels; modelIndex++){
        [self.modelMeta modelSetCurrentByIndex:modelIndex];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",
            [self.modelMeta modelGetTableName]];
        NSArray *results = [tables filteredArrayUsingPredicate:predicate];
        if([results count] == 0){
            MOScriptFile *file = [[MOScriptFile alloc]init];
            file.fileSql = [self generateCreateTableScriptForMeta];
            file.fileTimestamp=[[NSDate date] timeIntervalSince1970];
            [sqlScripts addObject:file];
            [file release];
        }
        else{
            NSArray*columns = [self getColumnDbMetaForTable:[self.modelMeta modelGetTableName]];
            int totalProperties = [self.modelMeta propertyCount];
            
            for(int propertyIndex = 0; propertyIndex < totalProperties; propertyIndex++){
                [self.modelMeta propertySetCurrentByIndex:propertyIndex];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",
                    [self.modelMeta propertyGetColumnName]];
                NSArray *results = [columns filteredArrayUsingPredicate:predicate];
                if([results count] == 0){
                    NSString* sqliteType = [self sqliteTypeForObjcType:[self.modelMeta propertyGetType]];
                    NSString*alterSql=[NSString stringWithFormat:@"alter table %@ add column %@ %@",
                        [self.modelMeta modelGetTableName],[self.modelMeta propertyGetColumnName],sqliteType];
                    MOScriptFile *file = [[MOScriptFile alloc]init];
                    file.fileSql = alterSql;
                    file.fileTimestamp=[[NSDate date] timeIntervalSince1970];
                    [sqlScripts addObject:file];
                    [file release];
                }
            }
        }
    }
    return sqlScripts;
}

-(NSString*)generateCreateTableScriptForMeta{
    NSMutableString *sql =[NSMutableString stringWithString:@"create table "];
    [sql appendString:[self.modelMeta modelGetTableName]];
    [sql appendString:@"("];
    int totalProperties = [self.modelMeta propertyCount];
    
    NSMutableArray* properties = [NSMutableArray array];
    for(int propertyIndex = 0; propertyIndex < totalProperties; propertyIndex++){
        [self.modelMeta propertySetCurrentByIndex:propertyIndex];
        if([self.modelMeta propertyGetIsKey]){
            [properties addObject:[NSString stringWithFormat:@"%@ INTEGER PRIMARY KEY",
                [self.modelMeta propertyGetColumnName]]];
        }
        else{
            NSString* sqliteType = [self sqliteTypeForObjcType:[self.modelMeta propertyGetType]];
            [properties addObject:[NSString stringWithFormat:@"%@ %@",
                [self.modelMeta propertyGetColumnName],sqliteType]];
        }
    }
    [sql appendString:[properties componentsJoinedByString:@","]];
    [sql appendString:@")"];
    return sql;
}

-(BOOL)runUpdateBeforeScripts:(NSArray*)before modelScripts:(NSArray*)model
    afterScripts:(NSArray*)after{
    
    if(![self executeScripts:self.runBeforeScripts])return false;
    if(![self executeScripts:model])return false;
    if(![self executeScripts:after])return false;
    return true;
}

-(BOOL)executeScripts:(NSArray*)scripts{
    for(id<IScriptFile> script in scripts){
        int rowsAffected = [self.repository executeSQL:[script sql] withParameters:nil];
        if(rowsAffected == -1){
            return false;
        }
        else{
            [self.repository executeSQL:
                    [NSString stringWithFormat:@"insert into %@(timestamp,runOn) values(?,?)",
                    [MODbMigrator migrationTableName]]
                withParameters:[NSArray arrayWithObjects:
                    [NSNumber numberWithDouble:[script timestamp]],
                    [NSDate date], nil]];
        }
        NSLog(@"migration: %@",[script sql]);
    }
    return true;
}

-(void)orderScriptFiles{
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [self.scriptFiles sortUsingDescriptors:sortDescriptors];
    [sortDescriptor release];
}

-(void)registerScriptFile:(id<IScriptFile>)scriptFile{
    [self.scriptFiles addObject:scriptFile];
}

-(void)createMigrationTable{
    NSString*setupSql=[NSString stringWithFormat:
        @"create table %@(timestamp number, runOn number)",
        [MODbMigrator migrationTableName]];
    [self.repository executeSQL:setupSql withParameters:nil];
}

-(NSArray*)getScriptFilesThatHaventBeenRun{
    [self orderScriptFiles];
    
    NSString*setupSql=[NSString stringWithFormat:@"select * from %@",[MODbMigrator migrationTableName]];
    NSArray* getRanScripts = [self.repository query:setupSql withParameters:nil];
    NSMutableArray* needToRun = [NSMutableArray array];
    
    for(id<IScriptFile> script in self.scriptFiles){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp == %f",[script timestamp]];
        NSArray *results = [getRanScripts filteredArrayUsingPredicate:predicate];
        if([results count] ==0){
            [needToRun addObject:script];
            continue;
        }
        break;
    }
    return needToRun;
}

-(void)checkCreateScriptTable{
   if([self tableExists:[MODbMigrator migrationTableName]] == false){
        [self createMigrationTable];
   }
}

-(BOOL)tableExists:(NSString*)tableName{
    return[[self.repository
        executeSQLScalar:@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?;"
        withParameters:[NSArray arrayWithObject:tableName]] intValue] > 0;
}

-(NSArray*)getTableDbMeta{
    NSString* sql =
        @"SELECT name FROM sqlite_master "
        "WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' "
        "UNION ALL "
        "SELECT name FROM sqlite_temp_master "
        "WHERE type IN ('table','view') "
        "ORDER BY 1";
    return [self.repository query:sql withParameters:nil];
}

-(NSArray*)getColumnDbMetaForTable:(NSString*)tableName{
    return [self.repository query:[NSString stringWithFormat:@"pragma table_info(%@)",tableName]
        withParameters:nil];
}

-(NSString*)sqliteTypeForObjcType:(NSString*)type{
    //float or double
    if([type compare:@"Tf"]==NSOrderedSame || [type compare:@"Td"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"float"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"double"]==NSOrderedSame){
        return @"NUMBER";
    }
    //int, long, bool, long long
    else if([type compare:@"Ti"]==NSOrderedSame || [type compare:@"Tl"]==NSOrderedSame
    || [type compare:@"Tc"]==NSOrderedSame || [type compare:@"Tq"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"int"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"long"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"bool"]==NSOrderedSame
    || [type caseInsensitiveCompare:@"long long"]==NSOrderedSame){
    
        return @"NUMBER";
    }
    else if ([type compare:@"T@\"NSString\""]==NSOrderedSame
    || [type caseInsensitiveCompare:@"NSString"]==NSOrderedSame) {
        
        return @"TEXT";
    }
    else if([type compare:@"T@\"NSNumber\""]==NSOrderedSame
    || [type caseInsensitiveCompare:@"NSNumber"]==NSOrderedSame){
        
        return @"NUMBER";
    }
    else if([type compare:@"T@\"NSDate\""]==NSOrderedSame
    || [type caseInsensitiveCompare:@"NSDate"]==NSOrderedSame){
       
       return @"NUMBER";
    }
    return @"";
}

@end
