//
//  GNData.m
//  CoreMeetingViewer
//
//  Created by Kirmanie Ravariere on 1/21/12.
//  Copyright (c) 2012 GeoNorth. All rights reserved.
//

#import "MORepository.h"
#import "ModelProperty.h"

//#define GNDATA_QUERY_DEBUG
//#define GNDATA_MOD_DEBUG

@interface MORepository ()

@property int busyRetryTimeout;
@end

@implementation MORepository

//====================================================================
//====================================================================
-(void)dealloc{
    [_filePathName release];
    [super dealloc];
}

//====================================================================
//====================================================================
-(id)init{
    self=[super init];
    if (self) {
        self.busyRetryTimeout =10;
        _filePathName = [MORepository getDefaultDatabasePath];
    }
    return self;
}

//====================================================================
//====================================================================
-(id)initWithDBFilePath:(NSString*)path{
    self=[super init];
    if (self) {
        _filePathName = path;
        self.busyRetryTimeout =10;
    }
    return self;
}

//====================================================================
//====================================================================
+(NSString*)getDefaultDatabasePath{
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	return [documentsDir stringByAppendingPathComponent:@"data.db"];
}

//====================================================================
//====================================================================
-(sqlite3*)getDatabase{
    return _database;
}

//====================================================================
//====================================================================
- (void)open {
    //already opened
	if (_database != NULL) {
        return;
    }    
    
    ///copy database from bundle if does not exist
    [self checkAndCreateDBFromPath];

    if (sqlite3_config(SQLITE_CONFIG_SERIALIZED) == SQLITE_OK) {
        //NSLog(@"Can now use sqlite on multiple threads, using the same connection");
    }
     
	if (sqlite3_open([self.filePathName UTF8String], &_database) != SQLITE_OK) {
		// Even though the open failed, call close to properly clean up resources.
        sqlite3_close(_database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(_database));
	}
}

//====================================================================
//====================================================================
-(void) checkAndCreateDBFromPath{
	
	// Check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
	NSString* databasePathAndName;
	NSString* databaseName;
	NSFileManager *fileManager;
	NSString *databasePathFromApp;
	
	databasePathAndName=self.filePathName;
	databaseName=[[self.filePathName lastPathComponent] stringByDeletingPathExtension];
	
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	fileManager = [NSFileManager defaultManager];
	
	// Check if the database has already been created in the users filesystem
	success = [fileManager fileExistsAtPath:databasePathAndName];
	
	// If the database already exists then return without doing anything
	if(success)return;
	
	// If not then proceed to copy the database from the application to the users filesystem
	
	// Get the path to the database in the application package
	databasePathFromApp = [[[NSBundle mainBundle] resourcePath] 
        stringByAppendingPathComponent:databaseName];
	
	// Copy the database from the package to the users filesystem
	[fileManager copyItemAtPath:databasePathFromApp toPath:databasePathAndName error:nil];
    
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
    NSString* tableName =[NSString stringWithCString:
        class_getName(type)encoding:NSUTF8StringEncoding];
    
    NSArray *properties=[MORepository getPropertiesForClass:type];
    NSString* pkName=[MORepository getPkName:object forTableName:tableName withProperties:properties];
    
    [self commit:object inTable:tableName withPK:pkName andProperties:properties];
}

//====================================================================
//====================================================================
-(void)commit:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName{
 
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    [self commit:object inTable:tableName withPK:pkName andProperties:properties];
}

//====================================================================
//====================================================================
-(void)commit:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName
andProperties:(NSArray*)properties{
    int pkId = [[object valueForKey:pkName]intValue];
    if (pkId==0) {
        [self insert:object intoTable:tableName withPK:pkName andProperties:properties];
    }
    else{
        [self update:object inTable:tableName withPK:pkName andProperties:properties];
    }
}

//====================================================================
//====================================================================
-(void)update:(id)object{
    
    if (!object) {
        return;
    }
    
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    
    NSString* tableName =[NSString stringWithCString:class_getName(type)
        encoding:NSUTF8StringEncoding];
    
    NSString* pkName=[MORepository getPkName:object forTableName:tableName withProperties:properties];
    
    [self update:object inTable:tableName withPK:pkName andProperties:properties];
}

//====================================================================
//====================================================================
-(void)update:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName{
    
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    
    [self insert:object intoTable:tableName withPK:pkName andProperties:properties];
    
}

//====================================================================
//====================================================================
-(void)update:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName
andProperties:(NSArray*)properties{
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    NSMutableArray *paramsArray=[[NSMutableArray alloc]init];
    int index=0;
    
    [sql appendString:@"update "];
    [sql appendString:tableName];
    [sql appendString:@" set "];
    
    for (ModelProperty *property in properties) {
        
        if ([property.propertyName caseInsensitiveCompare:pkName]==NSOrderedSame) {
            continue;
        }
        if (property.isReadOnly) {
            continue;
        }
        
        if (index>0) {
            [sql appendString:@","];
        }
        
        [sql appendString:property.propertyName];
        
        
        id value=[object valueForKey:property.propertyName];
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

    [sql release];
    [paramsArray release];
}

//====================================================================
//====================================================================
-(void)delete:(id)object{
    
    if (!object) {
        return;
    }
    
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    
    NSString* tableName =[NSString stringWithCString:class_getName(type)
         encoding:NSUTF8StringEncoding];
    
    NSString* pkName=[MORepository getPkName:object forTableName:tableName withProperties:properties];
    
    [self delete:object fromTable:tableName withPK:pkName];
}

//====================================================================
//====================================================================
-(void)delete:(id)object fromTable:(NSString*)tableName withPK:(NSString*)pkName{
 
    NSNumber *pkValue=(NSNumber*)[object valueForKey:pkName];
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    [sql appendString:@"delete from "];
    [sql appendString:tableName];
    [sql appendString:@" where "];
    [sql appendString:pkName];
    [sql appendString:@" = ? "];
    
    [self executeSQL:sql withParameters:[NSArray arrayWithObject:pkValue]];
    
    [sql release];
}

//====================================================================
//====================================================================
-(void)insert:(id)object{
    
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    
    NSString* tableName =[NSString stringWithCString:class_getName(type)
       encoding:NSUTF8StringEncoding];
    
    NSString* pkName=[MORepository getPkName:object forTableName:tableName withProperties:properties];
    
    [self insert:object intoTable:tableName withPK:pkName andProperties:properties];
}

//====================================================================
//====================================================================
-(void)insert:(id)object intoTable:(NSString*)tableName withPK:(NSString*)pkName{
    
    Class type=[object class];
    NSArray *properties=[MORepository getPropertiesForClass:type];
    
    [self insert:object intoTable:tableName withPK:pkName andProperties:properties];
}

//====================================================================
//====================================================================
-(void)insert:(id)object intoTable:(NSString*)tableName withPK:(NSString*)pkName
andProperties:(NSArray*)properties{
    
    NSMutableString *sql=[[NSMutableString alloc]init];
    NSMutableString *paramsSql=[[NSMutableString alloc]init];
    NSMutableArray *paramsArray=[[NSMutableArray alloc]init];
    int index=0;
    
    [sql appendString:@"insert into "];
    [sql appendString:tableName];
    [sql appendString:@"("];
    
    [paramsSql appendString:@" values("];
    for (ModelProperty *property in properties) {
     
        if ([property.propertyName caseInsensitiveCompare:pkName]==NSOrderedSame) {
            continue;
        }
        if (property.isReadOnly) {
            continue;
        }
        
        if (index>0) {
            [sql appendString:@","];
            [paramsSql appendString:@","];
        }
        
        [sql appendString:property.propertyName];
        
        
        id value=[object valueForKey:property.propertyName];
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
    
    [sql release];
    [paramsSql release];
    [paramsArray release];
}

//====================================================================
//====================================================================
-(NSArray*)queryColumn:(NSString*) sql  withParameters:(NSArray *)params{
    
    NSMutableArray *records=[[[NSMutableArray alloc]init]autorelease];
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
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params forType:(Class)clazz{
    #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"query: %@, withParameters:%@, forType:%@", sql,params,  NSStringFromClass(clazz));
    #endif    
    NSMutableArray *records=[[[NSMutableArray alloc]init]autorelease];
    
    NSArray *properties=[MORepository getPropertiesForClass:clazz];
    sqlite3_stmt* stat=[self executeSQLReader:sql withParameters:params];
	
	if (stat!=nil) {
        NSArray *columns=[MORepository getQueryColumns:stat];
        
		while (sqlite3_step(stat) == SQLITE_ROW) {
			
            id newObject = [MORepository mapRecord:stat toType:clazz
                withProperties:properties andColumns:columns];
            [records addObject:newObject];
		}
		
	}
	
	sqlite3_finalize(stat);
	
	return records;
    
}

//====================================================================
//====================================================================
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params{
     #ifdef GNDATA_QUERY_DEBUG
        NSLog(@"query: %@, withParameters:%@", sql,params);
    #endif
        
    NSMutableArray *records=[[[NSMutableArray alloc]init]autorelease];
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
            [record release];
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
            NSLog(@"SQL failed. '%s'.", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(compiledStatement);
    }
    @catch (NSException *exception) {
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
+(NSString*)getPkName:(id)object forTableName:(NSString*)tableName withProperties:(NSArray*)properties{
    
    NSString* pkName=@"Id";
    int index;

    index=[self indexOfCaseInsensitiveString:pkName inArray:properties stringProp:@"propertyName"];
    if (index==NSNotFound) {
        
        pkName=[tableName stringByAppendingString:@"Id"];
        index=[self indexOfCaseInsensitiveString:pkName inArray:properties stringProp:@"propertyName"];
        
        if (index==NSNotFound) {
            return @"";
        }
    }
    
    pkName=[(ModelProperty*)[properties objectAtIndex:index]propertyName];
    
    return pkName;
}

//====================================================================
//====================================================================
+(id)mapRecord:(sqlite3_stmt*)stat toType:(Class)clazz withProperties:(NSArray*)properties
andColumns:(NSArray*)columns{
    
    int columnIndex;
    id object = [[[clazz alloc] init]autorelease];
    
    for (ModelProperty *property in properties) {
        
        columnIndex=[self indexOfCaseInsensitiveString:property.propertyDbName inArray:columns];
        if (columnIndex==-1) {
            continue;
        }
        
        int sqlType =sqlite3_column_type(stat, columnIndex);
        NSString *type=property.propertyType;
        id propValue =nil;
        
        //float or double
        if([type compare:@"Tf"]==NSOrderedSame || [type compare:@"Td"]==NSOrderedSame){
        
            propValue=[NSNumber numberWithFloat:
                       [self floatForColumnIndex:columnIndex andStatement:stat]];
            
        }
        //int, long, bool, long long
        else if([type compare:@"Ti"]==NSOrderedSame || [type compare:@"Tl"]==NSOrderedSame
                || [type compare:@"Tc"]==NSOrderedSame || [type compare:@"Tq"]==NSOrderedSame){
        
            propValue=[NSNumber numberWithInteger:
                       [self intForColumnIndex:columnIndex andStatement:stat]];
        }
        else if ([type compare:@"T@\"NSString\""]==NSOrderedSame) {
            
            propValue=[self stringForColumnIndex:columnIndex andStatement:stat];
        }
        else if([type compare:@"T@\"NSNumber\""]==NSOrderedSame){
            
            if (sqlType == SQLITE_INTEGER) {
                propValue=[NSNumber numberWithInt:
                           [self intForColumnIndex:columnIndex andStatement:stat]];
            }
            else if(sqlType == SQLITE_FLOAT) {
                propValue=[NSNumber numberWithFloat:
                           [self floatForColumnIndex:columnIndex andStatement:stat]];
            }
        }
        else if([type compare:@"T@\"NSDate\""]==NSOrderedSame){
           
            propValue=[self dateForColumnIndex:columnIndex andStatement:stat];
        }

        if(propValue)
            [object setValue:propValue forKey:property.propertyName];
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
+(NSArray*)getPropertiesForClass:(Class)clazz{
    
    unsigned int count;
    
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
    
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        
        NSString* propName =[NSString  stringWithCString:propertyName 
                encoding:NSUTF8StringEncoding];
                
        NSRange prefix =[propName rangeOfString:@"na_"];
        if (prefix.length>0 && prefix.location==0) {
            continue;
        }
        
        ModelProperty *property=[[ModelProperty alloc]init];
        prefix =[propName rangeOfString:@"ro_"];
        property.isReadOnly=prefix.length>0 && prefix.location==0;
        property.propertyName = propName;      
        if (property.isReadOnly) {
            property.propertyDbName=[property.propertyName substringFromIndex:prefix.length];
        }
        else{
            property.propertyDbName=property.propertyName;
        }
        property.propertyType=[self property_getTypeString:properties[i]];
        
        [propertyArray  addObject:property];
        [property release];
    }
    free(properties);
    
    return propertyArray;
}

//====================================================================
//====================================================================
+(NSString*) property_getTypeString:( objc_property_t) property {
    
	const char * attrs = property_getAttributes( property );
	if ( attrs == NULL )
		return ( NULL );
    
	static char buffer[256];
	const char * e = strchr( attrs, ',' );
	if ( e == NULL )
		return ( NULL );
    
	int len = (int)(e - attrs);
	memcpy( buffer, attrs, len );
	buffer[len] = '\0';
    
	return [NSString  stringWithCString:buffer 
                               encoding:NSUTF8StringEncoding];
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
