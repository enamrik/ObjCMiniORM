//
//  MODbModelMeta.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/10/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "MODbModelMeta.h"

@interface MODbModelMeta()
@property(strong) NSMutableArray* meta;
@property(strong) NSMutableDictionary* currentModel;
@property(strong) NSMutableDictionary* currentProperty;
@end

@implementation MODbModelMeta

@synthesize meta,currentModel,currentProperty;

-(void)dealloc{
    self.currentModel=nil;
    self.meta=nil;
    self.currentProperty=nil;
    [super dealloc];
}

-(id)init{
    self=[super init];
    if (self) {
        self.meta=[NSMutableArray array];
    }
    return self;
}

-(void)modelAddByName:(NSString*)modelName{
    NSMutableDictionary* model = [self findModel:modelName];
    if(model==nil){
        model = [NSMutableDictionary dictionary];
        [model setObject:modelName forKey:@"name"];
        [model setObject:modelName forKey:@"tableName"];
        [model setObject:[NSMutableArray array] forKey:@"properties"];
        [self.meta addObject:model];
    }
    self.currentModel = model;
}

-(void)modelAddByType:(Class)modelType{
    NSString* modelName =[NSString stringWithCString:class_getName(modelType)
           encoding:NSUTF8StringEncoding];
    [self modelAddByName:modelName];
    [self addPropertiesForClass:modelType];
}
-(NSString*)modelGetName{
    return[self.currentModel objectForKey:@"name"];
}

-(void)modelSetCurrentByName:(NSString*)modelName{
    self.currentModel =[self findModel:modelName];
}

-(void)modelSetCurrentByIndex:(int)index{
    self.currentModel = [self.meta objectAtIndex:index];
}

-(void)modelSetTableName:(NSString*)tableName{
    [self.currentModel setObject:tableName forKey:@"tableName"];
}

-(NSString*)modelGetTableName{
    return [self.currentModel objectForKey:@"tableName"];
}

-(void)propertyAdd:(NSString*)propertyName{
    NSMutableDictionary* property = [self findProperty:propertyName];
    if(property==nil){
        property = [NSMutableDictionary dictionary];
        [property setObject:propertyName forKey:@"name"];
        [property setObject:propertyName forKey:@"columnName"];
        [[self.currentModel objectForKey:@"properties"]addObject:property];
    }
    self.currentProperty = property;
}

-(NSString*)propertyGetName{
    return [self.currentProperty objectForKey:@"name"];
}

-(void)propertySetCurrentByName:(NSString*)propertyName{
  self.currentProperty = [self findProperty:propertyName];
}

-(void)propertySetCurrentByIndex:(int)index{
    self.currentProperty = [[self.currentModel objectForKey:@"properties"]objectAtIndex:index];
}

-(void)propertySetColumnName:(NSString*)columnName{
    [self.currentProperty setObject:columnName forKey:@"columnName"];
}

-(NSString*)propertyGetColumnName{
    return [self.currentProperty objectForKey:@"columnName"];
}

-(void)propertySetType:(NSString*)typeName{
    [self.currentProperty setObject:typeName forKey:@"propertyType"];
}

-(NSString*)propertyGetType{
    return [self.currentProperty objectForKey:@"propertyType"];
}

-(void)propertySetIsKey:(BOOL)isKey{
    [self.currentProperty setObject:[NSNumber numberWithBool:isKey] forKey:@"isKey"];
}

-(BOOL)propertyGetIsKey{
    return [[self.currentProperty objectForKey:@"isKey"]boolValue];
}

-(int)modelCount{
    return [self.meta count];
}

-(int)propertyCount{
    return [[self.currentModel objectForKey:@"properties"] count];
}


-(NSMutableDictionary*)findProperty:(NSString*)name{
    NSArray* properties = [self.currentModel objectForKey:@"properties"];
    for(NSMutableDictionary* property in properties){
        if([[property objectForKey:@"name"]isEqualToString:name]){
            return property;
        }
    }
    return nil;
}

-(NSMutableDictionary*)findModel:(NSString*)name{
    for(NSMutableDictionary* dic in self.meta){
        if([[dic objectForKey:@"name"]isEqualToString:name]){
            return dic;
        }
    }
    return nil;
}

-(void)addPropertiesForClass:(Class)clazz{
    unsigned int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    
    for (int i = 0; i < count ; i++){
        const char* propertyName = property_getName(properties[i]);
        
        NSString* propName =[NSString  stringWithCString:propertyName
                encoding:NSUTF8StringEncoding];
        [self propertyAdd:propName];
        if([propName caseInsensitiveCompare:
            [NSString stringWithFormat:@"%@Id",[self modelGetTableName]]]==NSOrderedSame){
            [self propertySetIsKey:true];
        }
        [self propertySetType:[self property_getTypeString:properties[i]]];
    }
    free(properties);
}

-(NSString*) property_getTypeString:( objc_property_t) property {
    
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
    
	return [NSString  stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end
