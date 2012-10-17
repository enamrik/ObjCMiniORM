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

//if the model already exists, it will be left alone and made current
-(void)modelAddByName:(NSString*)modelName;

//if the model already exists, it will be left alone and made current
-(void)modelAddByType:(Class)modelType;

-(NSString*)modelGetName;
-(BOOL)modelSetCurrentByName:(NSString*)modelName;
-(BOOL)modelSetCurrentByIndex:(int)index;
-(void)modelSetTableName:(NSString*)tableName;
-(NSString*)modelGetTableName;
-(NSString*)modelGetPrimaryKeyName;

//if the property already exists, it will be left alone and made current
-(void)propertyAdd:(NSString*)propertyName;

-(NSString*)propertyGetName;
-(BOOL)propertySetCurrentByName:(NSString*)propertyName;
-(BOOL)propertySetCurrentByIndex:(int)index;
-(void)propertySetColumnName:(NSString*)columnName;
-(NSString*)propertyGetColumnName;
-(void)propertySetIsKey:(BOOL)isKey;
-(BOOL)propertyGetIsKey;
-(void)propertySetType:(NSString*)typeName;
-(NSString*)propertyGetType;
-(void)propertySetIsReadOnly:(BOOL)isReadOnly;
-(BOOL)propertyGetIsReadOnly;
-(void)propertySetIgnore:(BOOL)ignore;
-(BOOL)propertyGetIgnore;

-(int)modelCount;
-(int)propertyCount;
-(void)merge:(MODbModelMeta*)modelMeta;

@end
