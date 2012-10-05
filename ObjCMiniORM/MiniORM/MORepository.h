//
//  GNData.h
//  CoreMeetingViewer
//
//  Created by Kirmanie Ravariere on 1/21/12.
//  Copyright (c) 2012 GeoNorth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <objc/runtime.h>

@interface MORepository : NSObject{
    sqlite3 *_database;
}

@property(readonly)NSString *filePathName;

-(id)init;
-(id)initWithDBFilePath:(NSString*)path;
- (void)open;
-(BOOL) close;

-(void)commit:(id)object;
-(void)commit:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName;
-(void)update:(id)object;
-(void)update:(id)object inTable:(NSString*)tableName withPK:(NSString*)pkName;
-(void)delete:(id)object;
-(void)delete:(id)object fromTable:(NSString*)tableName withPK:(NSString*)pkName;
-(void)insert:(id)object;
-(void)insert:(id)object intoTable:(NSString*)tableName withPK:(NSString*)pkName;

-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params forType:(Class)clazz;
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params;

-(NSString*)executeSQLScalar:(NSString*)sqlText withParameters:(NSArray *)parameters;
-(NSInteger)executeInsert:(NSString*)sqlText withParameters:(NSArray *)parameters;
-(int)executeSQL:(NSString*)sqlText withParameters:(NSArray *)parameters;
-(sqlite3_stmt*)executeSQLReader:(NSString*)sqlText  withParameters:(NSArray *)parameters;

- (void)beginTransaction;
- (void)beginDeferredTransaction;
-(void)rollback;
-(void)commitTransaction;

-(sqlite3*)sqliteDatabase;
+(NSString*)defaultDatabasePath;

@end
