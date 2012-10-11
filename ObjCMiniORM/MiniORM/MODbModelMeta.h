//
//  MODbModelMeta.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/10/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface MODbModelMeta : NSObject

-(void)modelAddByName:(NSString*)modelName;
-(void)modelAddByType:(Class)modelType;
-(NSString*)modelGetName;
-(void)modelSetCurrentByName:(NSString*)modelName;
-(void)modelSetCurrentByIndex:(int)index;
-(void)modelSetTableName:(NSString*)tableName;
-(NSString*)modelGetTableName;

-(void)propertyAdd:(NSString*)propertyName;
-(NSString*)propertyGetName;
-(void)propertySetCurrentByName:(NSString*)propertyName;
-(void)propertySetCurrentByIndex:(int)index;
-(void)propertySetColumnName:(NSString*)columnName;
-(NSString*)propertyGetColumnName;
-(void)propertySetIsKey:(BOOL)isKey;
-(BOOL)propertyGetIsKey;
-(void)propertySetType:(NSString*)typeName;
-(NSString*)propertyGetType;

-(int)modelCount;
-(int)propertyCount;

@end
