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
@class MODbModelMeta;

@interface MORepository : NSObject{
    sqlite3 *_database;
}

-(id)init;
-(id)initWithDBFilePath:(NSString*)pathName;
-(id)initWithBundleFile:(NSString*)name;
-(id)initWithBundleFile:name dbFilePath:pathName;

-(void)resetDB;

-(NSString*)getFilePathName;
-(void) mergeModelMeta:(MODbModelMeta*)meta;
-(BOOL)open;
-(BOOL)isOpened;
-(BOOL) close;

-(void)commit:(id)object;
-(void)update:(id)object;
-(void)delete:(id)object;
-(void)insert:(id)object;

-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params forType:(Class)clazz;
-(NSArray*)query:(NSString*) sql  withParameters:(NSArray *)params;
-(NSArray*)queryForType:(Class)type;
-(NSArray*)queryForType:(Class)type key:(int)key;
-(NSArray*)queryForType:(Class)type whereClause:(NSString*)where;

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
