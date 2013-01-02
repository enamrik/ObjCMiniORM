//
//  GNData.m
//  CoreMeetingViewer
//
//  Created by Kirmanie Ravariere on 1/21/12.
//  Copyright (c) 2012 GeoNorth. All rights reserved.
//

#import "MORepository.h"
#import "MODbModelMeta.h"

//#define GNDATA_QUERY_DEBUG
//#define GNDATA_MOD_DEBUG

@interface MORepository ()
@property(strong)MODbModelMeta* modelMeta;
@property(copy)NSString* bundleFile;
@property int busyRetryTimeout;
@property(strong)NSString *filePathName;
@end

@implementation MORepository

//====================================================================
//====================================================================
-(id)init{
    self=[super init];
    if (self) {
        self.filePathName = [MORepository defaultDatabasePath];
        [self initSetup];
    }
    return self;
}

//====================================================================
//====================================================================
-(id)initWithDBFilePath:(NSString*)pathName{
    self=[super init];
    if (self) {
        self.filePathName = pathName;
        [self initSetup];
    }
    return self;
}

//====================================================================
//====================================================================
-(id)initWithBundleFile:(NSString*)name{
    self=[super init];
    if (self) {
        self.bundleFile = name;
        self.filePathName = [[[MORepository defaultDatabasePath]stringByDeletingLastPathComponent]
            stringByAppendingPathComponent:self.bundleFile];
        [self initSetup];
    }
    return self;
}

//====================================================================
//====================================================================
-(id)initWithBundleFile:name dbFilePath:pathName{
    self=[super init];
    if (self) {
        self.bundleFile = name;
        self.filePathName = pathName;
        [self initSetup];
    }
    return self;
}

//====================================================================
//====================================================================
-(void)initSetup{
    self.busyRetryTimeout =10;
    self.modelMeta = [[MODbModelMeta alloc]init];
    _database = NULL;
}

//====================================================================
// Resets the whole database file (means all migration needs to be
// executed again)
//====================================================================
-(void)resetDB {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    [filemgr removeItemAtPath: self.filePathName error: NULL];
    [self initSetup];
}

//====================================================================
//====================================================================
-(void) mergeModelMeta:(MODbModelMeta*)meta{
    [self.modelMeta merge:meta];
}

//====================================================================
//====================================================================
-(NSString*)getFilePathName{
    return self.filePathName;
}

//====================================================================
//====================================================================
+(NSString*)defaultDatabasePath{
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	return [documentsDir stringByAppendingPathComponent:@"data.db"];
}

//====================================================================
//====================================================================
-(sqlite3*)sqliteDatabase{
    return _database;
}

//====================================================================
//====================================================================
-(BOOL)isOpened{
	return _database != NULL;
}

//====================================================================
//====================================================================
- (BOOL)open {
    //already opened
	if (_database != NULL) {
        return YES;
    }    
    
    ///copy database from bundle if does not exist
    [self checkAndCreateDBFromBundle];

    if (sqlite3_config(SQLITE_CONFIG_SERIALIZED) == SQLITE_OK) {
        //NSLog(@"Can now use sqlite on multiple threads, using the same connection");
    }
     
	if (sqlite3_open([self.filePathName UTF8String], &_database) != SQLITE_OK) {
		// Even though the open failed, call close to properly clean up resources.
        sqlite3_close(_database);
        NSLog(@"Failed to open database with message '%s'.", sqlite3_errmsg(_database));
        return NO;
	}
    return YES;
}

//====================================================================
//====================================================================
-(void) checkAndCreateDBFromBundle{

    //if database exist, do nothing
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:self.filePathName]){
        return;
    }
    NSError*error;
    //if we have a database file in the bundle, use it
    if(self.bundleFile){
    	NSString *dbBundlePath = [[[NSBundle mainBundle] resourcePath]
            stringByAppendingPathComponent:self.bundleFile];
        [fileManager copyItemAtPath:dbBundlePath toPath:self.filePathName error:&error];
    }
    //if we get here, sqlite will automatically create the database if not found at the path the user
    //specified or at the default path 
}

//====================================================================
//====================================================================
-(BOOL) close {
	if (_database == NULL) {
        return YES;
    }
    
    int  rc;
    int numberOfRetries = 0;
	int busyRetryTimeout=self.busyRetryTimeout;
    BOOL retry = NO;
	
    do {
        retry   = NO;
        rc      = sqlite3_close(_database);
        if (SQLITE_BUSY == rc) {
            retry = YES;
            //usleep(20);
            if (busyRetryTimeout && (numberOfRetries++ > busyRetryTimeout)) {
                NSLog(@"%s:%d", __FUNCTION__, __LINE__);
                NSLog(@"Database busy, unable to close");
                return NO;
            }
        }
        else if (SQLITE_OK != rc) {
            NSLog(@"error closing!: %d", rc);
        }
    }
    while (retry);
    
	_database = NULL;
    return YES;
}

//====================================================================
//====================================================================
-(void)commit:(id)object{
    if (!object) {
        return;
    }
    
    Class type=[object class];
    [self.modelMeta modelAddByType:type];
    
    int pkId = [[object valueForKey:[self.modelMeta modelGetPrimaryKeyName]]intValue];
    if (pkId==0) {
        [self insert:object];
    }
    else{
        [self update:object];
    }
}

//====================================================================
//====================================================================
-(void)update:(id)object{
    if (!object) {
        return;
    }
    
    Class type=[object class];
    [self.modelMeta modelAddByType:type];
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    NSMutableArray *paramsArray=[[NSMutableArray alloc]init];
    
    NSString* pkName =[self.modelMeta modelGetPrimaryKeyName];
    NSString* tableName = [self.modelMeta modelGetTableName];
    
    [sql appendString:@"update "];
    [sql appendString:tableName];
    [sql appendString:@" set "];
    
    int propertyCount  = [self.modelMeta propertyCount];
    int index=0;
    for(int propertyIndex = 0; propertyIndex<propertyCount;propertyIndex++){
        [self.modelMeta propertySetCurrentByIndex:propertyIndex];
        
        if ([self.modelMeta propertyGetIsKey]
            ||[self.modelMeta propertyGetIsReadOnly]
            || [self.modelMeta propertyGetIgnore]) {
            continue;
        }
        
        if (index>0) {
            [sql appendString:@","];
        }
        
        [sql appendString:[self.modelMeta propertyGetColumnName]];
        
        
        id value=[object valueForKey:[self.modelMeta propertyGetName]];
        if (value) {
            [sql appendString:@" = ?"];
            [paramsArray addObject:value];
        }else{
            [sql appendString:@" = null"];
        }
        
        index++;
    }
    
    [sql appendString:@" where "];
    [sql appendString:pkName];
    [sql appendString:@" = ? "];
    
    NSNumber *pkValue=(NSNumber*)[object valueForKey:pkName];
    [paramsArray addObject:pkValue];
    
    [self executeSQL:sql withParameters:paramsArray];

}

//====================================================================
//====================================================================
-(void)delete:(id)object{
 
    if (!object) {
        return;
    }
    
    Class type=[object class];
    [self.modelMeta modelAddByType:type];
    
    NSString* tableName = [self.modelMeta modelGetTableName];
    NSString* pkName =[self.modelMeta modelGetPrimaryKeyName];
    NSNumber *pkValue=(NSNumber*)[object valueForKey:pkName];
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    [sql appendString:@"delete from "];
    [sql appendString:tableName];
    [sql appendString:@" where "];
    [sql appendString:pkName];
    [sql appendString:@" = ? "];
    
    [self executeSQL:sql withParameters:[NSArray arrayWithObject:pkValue]];
    
}

//====================================================================
//====================================================================
-(void)insert:(id)object{

    if (!object) {
        return;
    }
    
    Class type=[object class];
    [self.modelMeta modelAddByType:type];
    
    NSString* pkName =[self.modelMeta modelGetPrimaryKeyName];
    NSString* tableName = [self.modelMeta modelGetTableName];
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    NSMutableString *paramsSql=[[NSMutableString alloc]init];
    NSMutableArray *paramsArray=[[NSMutableArray alloc]init];
    int index=0;
    
    [sql appendString:@"insert into "];
    [sql appendString:tableName];
    [sql appendString:@"("];
    
    [paramsSql appendString:@" values("];
    
    int propertyCount  = [self.modelMeta propertyCount];
    for(int propertyIndex = 0; propertyIndex<propertyCount;propertyIndex++){
        [self.modelMeta propertySetCurrentByIndex:propertyIndex];
        
        if ([self.modelMeta propertyGetIsKey]
            ||[self.modelMeta propertyGetIsReadOnly]
            || [self.modelMeta propertyGetIgnore]) {
            continue;
        }
        
        if (index>0) {
            [sql appendString:@","];
            [paramsSql appendString:@","];
        }
        
        [sql appendString:[self.modelMeta propertyGetColumnName]];
        
        id value=[object valueForKey:[self.modelMeta propertyGetName]];
        if (value) {
            [paramsSql appendString:@"?"];
            [paramsArray addObject:value];
        }
        else{
            [paramsSql appendString:@"null"];
        }
     
        index++;
    }
    [sql appendString:@")"];
    [paramsSql appendString:@")"];
    
    [sql appendString:paramsSql];

    int newId = [self executeInsert:sql withParameters:paramsArray];
    if (newId>0) {
        [object setValue:[NSNumber numberWithInt:newId] forKey:pkName];
    }
    
}

//====================================================================
//====================================================================
-(NSArray*)queryColumn:(NSString*) sql  withParameters:(NSArray *)params{
    
    NSMutableArray *records=[[NSMutableArray alloc]init];
    sqlite3_stmt* stat=[self executeSQLReader:sql withParameters:params];
	
	if (stat!=nil) {
		while (sqlite3_step(stat) == SQLITE_ROW) {
            id value = [MORepository getColumnValue:0 forStatement:stat];
            if (value) {
                [records addObject:value];
            }
		}
	}
	
	sqlite3_finalize(stat);
	return records;
}

//====================================================================
//====================================================================
- (void)beginTransaction {
    [self executeSQL:@"BEGIN EXCLUSIVE TRANSACTION;" withParameters:nil];
}

//====================================================================
//====================================================================
- (void)beginDeferredTransaction {
    [self executeSQL:@"BEGIN DEFERRED TRANSACTION;" withParameters:nil];
}

//====================================================================
//====================================================================
-(void)rollback {
    [self executeSQL:@"ROLLBACK TRANSACTION;" withParameters:nil];
}

//====================================================================
//====================================================================
-(void)commitTransaction{
    [self executeSQL:@"COMMIT TRANSACTION;" withParameters:nil];
}

//====================================================================
//====================================================================
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params forType:(Class)type{
    #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"query: %@, withParameters:%@, forType:%@", sql,params,  NSStringFromClass(type));
    #endif    
    
    NSMutableArray *records=[[NSMutableArray alloc]init];
    sqlite3_stmt* stat=[self executeSQLReader:sql withParameters:params];
	
    [self.modelMeta modelAddByType:type];
	if (stat!=nil) {
        NSArray *columns=[MORepository getQueryColumns:stat];
		while (sqlite3_step(stat) == SQLITE_ROW) {
            id newObject = [self mapRecord:stat andColumns:columns forType:type];
            [records addObject:newObject];
		}
	}
	
	sqlite3_finalize(stat);
	return records;
}

//====================================================================
// Queries all records for a specific type
//====================================================================
-(NSArray*)queryForType:(Class)type {

    // add or set the current model
    [self.modelMeta modelAddByType:type];

    // get table name for type
    NSString* tableName = [self.modelMeta modelGetTableName];
    
    // use the table name
    return [self query:[NSString stringWithFormat:@"select * from %@", tableName] withParameters:nil forType:type];
}

//====================================================================
//====================================================================
-(NSArray*)queryForType:(Class)type whereClause:(NSString*)where
withParameters:(NSArray *)params{

    [self.modelMeta modelAddByType:type];
    NSString* tableName = [self.modelMeta modelGetTableName];
    return [self query:[NSString stringWithFormat:
        @"select * from %@ where %@", tableName, where]
        withParameters:params forType:type];
}

//====================================================================
//====================================================================
-(id)querySingleForType:(Class)type whereClause:(NSString*)where
withParameters:(NSArray *)params{

    [self.modelMeta modelAddByType:type];
    NSString* tableName = [self.modelMeta modelGetTableName];
    NSArray* records = [self query:[NSString stringWithFormat:
        @"select * from %@ where %@", tableName, where]
        withParameters:params forType:type];
    
    return [records count]==0? nil:[records objectAtIndex:0];
}

//====================================================================
//====================================================================
-(id)queryForType:(Class)type key:(int)key{

    [self.modelMeta modelAddByType:type];
    NSString* tableName = [self.modelMeta modelGetTableName];
    NSString*keyName =[self.modelMeta modelGetPrimaryKeyName];
    
    NSArray* records = [self query:[NSString stringWithFormat:
        @"select * from %@ where %@ = ?", tableName, keyName]
        withParameters:[NSArray arrayWithObject:[NSNumber numberWithInt:key]] forType:type];
    
    return [records count]==0? nil:[records objectAtIndex:0];
}

//====================================================================
//====================================================================
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params{
     #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"query: %@, withParameters:%@", sql,params);
    #endif
        
    NSMutableArray *records=[[NSMutableArray alloc]init];
    sqlite3_stmt* stat=[self executeSQLReader:sql withParameters:params];
	
	if (stat!=nil) {
        
        NSArray *columns=[MORepository getQueryColumns:stat];
        int totalCols = [columns count];
        
		while (sqlite3_step(stat) == SQLITE_ROW) {
			
            NSMutableDictionary *record =[[NSMutableDictionary alloc]init];
            for (int index = 0; index < totalCols; index++) {
                
                NSString* column  = [columns objectAtIndex:index];
                id value = [MORepository getColumnValue:index forStatement:stat];
                
                if (value) {
                    [record setObject:value forKey:column];
                }
                else{
                    [record setObject:[NSNull null] forKey:column];
                }
            }
            [records addObject:record];
		}
	}
	
	sqlite3_finalize(stat);
	
	return records;
    
}

//====================================================================
//====================================================================
-(NSString*)executeSQLScalar:(NSString*)sqlText withParameters:(NSArray *)parameters{
     #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"executeSQLScalar: %@, withParameters:%@", sqlText,parameters);
    #endif

	BOOL AllOkay;	
	sqlite3_stmt *compiledStatement;
	NSString* Results;
    
    Results=@"";
	AllOkay=TRUE;
	
	@try {
        
        AllOkay=[self prepareStatement:&compiledStatement forSql:sqlText inDb:_database];
        
        if (AllOkay==TRUE) {
            
            [MORepository bindParameters:parameters toStatement:compiledStatement];
            
            if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                Results=[MORepository stringForColumnIndex:0 andStatement:compiledStatement];
            }
        }
        else{
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(compiledStatement);
    }
    @catch (NSException *exception) {
        NSLog(@"Error in executeSQLScalar: %@",[exception description]);
    }
    
	return Results;   
}

//====================================================================
//====================================================================
-(NSInteger)executeInsert:(NSString*)sqlText withParameters:(NSArray *)parameters{
    #ifdef GNDATA_MOD_DEBUG
        NSLog(@"executeInsert: %@, withParameters:%@", sqlText,parameters);
    #endif
    
	BOOL AllOkay;	
	sqlite3_stmt *compiledStatement;
	int RetVal=-1;
    
	AllOkay=TRUE;

	@try {
        
        AllOkay=[self prepareStatement:&compiledStatement forSql:sqlText inDb:_database];
        
        if (AllOkay==TRUE) {
            
            [MORepository bindParameters:parameters toStatement:compiledStatement];
            
            if(SQLITE_DONE != sqlite3_step(compiledStatement))
                AllOkay=FALSE;
            else
                RetVal=[[NSNumber numberWithInt: sqlite3_last_insert_rowid(_database)] integerValue];
        }
        else{
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(_database));
        }
    
        sqlite3_finalize(compiledStatement);
    }
    @catch (NSException *exception) {
        NSLog(@"Error in executeInsert: %@",[exception description]);
    }
    
	return RetVal;
}

//====================================================================
//====================================================================
-(int)executeSQL:(NSString*)sqlText withParameters:(NSArray *)parameters{
    #ifdef GNDATA_MOD_DEBUG
        NSLog(@"executeSQL: %@, withParameters:%@", sqlText,parameters);
    #endif
    
	BOOL AllOkay;	
	sqlite3_stmt *compiledStatement;
    int rowsAffected=0;
    
	AllOkay=TRUE;
	
	@try {
        
        AllOkay=[self prepareStatement:&compiledStatement forSql:sqlText inDb:_database];
        
        if (AllOkay==TRUE) {
            
            [MORepository bindParameters:parameters toStatement:compiledStatement];
            
            if(SQLITE_DONE != sqlite3_step(compiledStatement))
                AllOkay=false;
            else
                rowsAffected=sqlite3_changes(_database);
        }
        
        if (AllOkay==false){
            rowsAffected = -1;
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(compiledStatement);
    }
    @catch (NSException *exception) {
        rowsAffected=-1;
        NSLog(@"Error in executeSQL:%@",[exception description]);
    }
    return rowsAffected;
}

//====================================================================
//====================================================================
-(sqlite3_stmt*)executeSQLReader:(NSString*)sqlText  withParameters:(NSArray *)parameters{
    #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"executeSQLReader: %@, withParameters:%@", sqlText,parameters);
    #endif

	BOOL AllOkay;	
	sqlite3_stmt *compiledStatement;
	
	AllOkay=TRUE;
	
	@try {
        
        AllOkay=[self prepareStatement:&compiledStatement forSql:sqlText inDb:_database];
        
        if (AllOkay==TRUE) {
            [MORepository bindParameters:parameters toStatement:compiledStatement];
            return compiledStatement;
        }
        else{
            sqlite3_finalize(compiledStatement);
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(_database));
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    
	return nil;
}

//====================================================================
//====================================================================
-(BOOL)prepareStatement:(sqlite3_stmt **)compiledStatement forSql:(NSString*)sqlText inDb:(sqlite3*)database{
    
    BOOL AllOkay=true;
    const char *sqlStatement;
    BOOL retry = NO;
    int rc= 0;
    int numberOfRetries = 0;
	int busyRetryTimeout=self.busyRetryTimeout;
    
	//convert to NSString to const char*
	sqlStatement = [sqlText UTF8String];
    
    do{
        
        retry=NO;
        rc=sqlite3_prepare_v2(database, sqlStatement, -1, compiledStatement, NULL);
        
        if (rc == SQLITE_BUSY) {
            
            retry = YES;
            
            //tried as many many tiems as we are willing to so consider attempt a failure
            if (busyRetryTimeout && (numberOfRetries++ > busyRetryTimeout)) {
                NSLog(@"%s:%d Database busy", __FUNCTION__, __LINE__);
                NSLog(@"Database busy");
                AllOkay=FALSE;
                break;
            }
        }
        else if (SQLITE_OK != rc) {
            //bad sql statement, log failure
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(database));
            NSLog(@"DB Query: %@", sqlText);
            AllOkay=FALSE;
            break;			
        }
        
    }
    while (retry);
    
    return AllOkay;
}

//====================================================================
//====================================================================
-(id)mapRecord:(sqlite3_stmt*)stat andColumns:(NSArray*)columns forType:(Class)type{
    
    int columnIndex;
    id object = [[type alloc] init];
    
    int propertyCount  = [self.modelMeta propertyCount];
    
    for(int propertyIndex = 0; propertyIndex<propertyCount;propertyIndex++){
        [self.modelMeta propertySetCurrentByIndex:propertyIndex];
        
        if ([self.modelMeta propertyGetIgnore]) {
            continue;
        }
        
        columnIndex=[MORepository indexOfCaseInsensitiveString:
            [self.modelMeta propertyGetColumnName] inArray:columns];
        if (columnIndex==-1) {
            continue;
        }
        
        int sqlType =sqlite3_column_type(stat, columnIndex);
        NSString *type=[self.modelMeta propertyGetType];
        id propValue =nil;
        
        //float or double
        if([type compare:@"Tf"]==NSOrderedSame || [type compare:@"Td"]==NSOrderedSame){
        
            propValue=[NSNumber numberWithFloat:
                       [MORepository floatForColumnIndex:columnIndex andStatement:stat]];
            
        }
        //int, long, bool, long long
        else if([type compare:@"Ti"]==NSOrderedSame || [type compare:@"Tl"]==NSOrderedSame
                || [type compare:@"Tc"]==NSOrderedSame || [type compare:@"Tq"]==NSOrderedSame){
        
            propValue=[NSNumber numberWithInteger:
                       [MORepository intForColumnIndex:columnIndex andStatement:stat]];
        }
        else if ([type compare:@"T@\"NSString\""]==NSOrderedSame) {
            
            propValue=[MORepository stringForColumnIndex:columnIndex andStatement:stat];
        }
        else if([type compare:@"T@\"NSNumber\""]==NSOrderedSame){
            
            if (sqlType == SQLITE_INTEGER) {
                propValue=[NSNumber numberWithInt:
                           [MORepository intForColumnIndex:columnIndex andStatement:stat]];
            }
            else if(sqlType == SQLITE_FLOAT) {
                propValue=[NSNumber numberWithFloat:
                           [MORepository floatForColumnIndex:columnIndex andStatement:stat]];
            }
        }
        else if([type compare:@"T@\"NSDate\""]==NSOrderedSame){
           
            propValue=[MORepository dateForColumnIndex:columnIndex andStatement:stat];
        }

        if(propValue)
            [object setValue:propValue forKey:[self.modelMeta propertyGetName]];
    }
      
    return object;
}

//====================================================================
//====================================================================
+(id)getColumnValue:(int)columnIndex forStatement:(sqlite3_stmt*)stat{
    
    id propValue =nil;
    int sqlType =sqlite3_column_type(stat, columnIndex);
    
    if(sqlType==SQLITE_FLOAT){
        propValue=[NSNumber numberWithFloat:
            [self floatForColumnIndex:columnIndex andStatement:stat]];
        
    }
    else if(sqlType ==  SQLITE_INTEGER){
        propValue=[NSNumber numberWithInteger:
                   [self intForColumnIndex:columnIndex andStatement:stat]];
    }
    else if (sqlType == SQLITE_TEXT) {
        propValue=[self stringForColumnIndex:columnIndex andStatement:stat];
    }
    
    return  propValue;
}

//====================================================================
//====================================================================
+(NSArray*)getQueryColumns:(sqlite3_stmt*)stat{
    
    NSMutableArray* propertyArray = [NSMutableArray array];
    int index=0;
    
    while (true) {
        const char * name = sqlite3_column_name(stat, index);
        if (name) {
            [propertyArray addObject:[NSString  stringWithCString:name 
                  encoding:NSUTF8StringEncoding]];
        }
        else{
            break;
        }
        index++;
    }
    
    return propertyArray;
    
}

//====================================================================
//====================================================================
+(void)bindParameters:(NSArray*)parameters toStatement:(sqlite3_stmt *)compiledStatement{

    if (!parameters) {
        return;
    }
    
    for (int i = 0; i < [parameters count]; i++) {
        id obj = [parameters objectAtIndex:i];
        if ([obj isKindOfClass:[NSString class]]) {
            const char * utfString = [(NSString *)obj UTF8String];
            sqlite3_bind_text(compiledStatement, i+1, utfString,
                              (int)strlen(utfString), SQLITE_TRANSIENT);
        } else if ([obj isKindOfClass:[NSData class]]) {
            sqlite3_bind_blob(compiledStatement, i+1, [(NSData *)obj bytes], 
                              (int)[(NSData *)obj length], SQLITE_TRANSIENT);
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            if ([(NSNumber *)obj doubleValue] == (double)([(NSNumber *)obj longLongValue])) {
                sqlite3_bind_double(compiledStatement, i+1, [(NSNumber *)obj doubleValue]);
            } else {
                sqlite3_bind_int64(compiledStatement, i+1, [(NSNumber *)obj longLongValue]);
            }
        }else if([obj isKindOfClass:[NSDate class]]){
            double timestamp=[(NSDate*)obj timeIntervalSince1970];
            sqlite3_bind_double(compiledStatement, i+1, timestamp);
        }
    }
    
}

//====================================================================
//====================================================================
+(NSString*) stringForColumnIndex:(int)columnIdx andStatement:(sqlite3_stmt*)compiledStatement {
    
    if (sqlite3_column_type(compiledStatement, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
		return @"";
	}
    const char *c = (const char *)sqlite3_column_text(compiledStatement, columnIdx);
    if (!c) {
        // null row.
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}

//====================================================================
//====================================================================
+(NSDate*)dateForColumnIndex:(int)columnIdx andStatement:(sqlite3_stmt*)compiledStatement {
    if (sqlite3_column_type(compiledStatement, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
		return nil;
	}
    long long dateLong=sqlite3_column_double(compiledStatement, columnIdx);
    if (dateLong==0) {
        return nil;
    }
	return [NSDate dateWithTimeIntervalSince1970:dateLong];
}

//====================================================================
//====================================================================
+(NSInteger)intForColumnIndex:(int)columnIdx andStatement:(sqlite3_stmt*)compiledStatement {
	return sqlite3_column_int(compiledStatement, columnIdx);
}

//====================================================================
//====================================================================
+(CGFloat)floatForColumnIndex:(int)columnIdx andStatement:(sqlite3_stmt*)compiledStatement {
	return sqlite3_column_double(compiledStatement, columnIdx);
}

//====================================================================
//====================================================================
+(NSUInteger)indexOfCaseInsensitiveString:(NSString *)aString inArray:(NSArray*)array {
    
    NSUInteger index = 0;
    for (NSString *object in array) {
        if ([object caseInsensitiveCompare:aString] == NSOrderedSame) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

//====================================================================
//====================================================================
+(NSUInteger)indexOfCaseInsensitiveString:(NSString *)aString inArray:(NSArray*)array stringProp:(NSString*)propName {
    
    NSUInteger index = 0;
    for (NSString *object in array) {
        if ([[object valueForKey:propName] caseInsensitiveCompare:aString] == NSOrderedSame) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

@end
