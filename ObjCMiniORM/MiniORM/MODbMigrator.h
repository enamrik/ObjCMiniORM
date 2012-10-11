//
//  MODbMigrator.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/6/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MORepository,MODbModelMeta;

@protocol IScriptFile <NSObject>
-(double)timestamp;
-(NSString*)sql;
-(BOOL)runBeforeModelUpdate;
@end


@interface MODbMigrator : NSObject

@property(strong)NSArray* runBeforeScripts;
@property(strong)NSArray* modelScripts;
@property(strong)NSArray* runAfterScripts;

-(id)initWithRepo:(MORepository*)repo andMeta:(MODbModelMeta*)meta;
-(BOOL)updateDatabaseAndRunScripts:(BOOL)runScripts;
-(NSArray*)registeredScriptFiles;
-(void)registerScriptFile:(id<IScriptFile>)scriptFile;
+(NSString*)migrationTableName;
@end
