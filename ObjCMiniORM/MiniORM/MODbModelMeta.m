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

-(BOOL)modelSetCurrentByName:(NSString*)modelName{
    self.currentModel =[self findModel:modelName];
    return self.currentModel != nil;
}

-(BOOL)modelSetCurrentByIndex:(int)index{
    if(index >= [self modelCount]) return false;
    self.currentModel = [self.meta objectAtIndex:index];
    return true;
}

-(void)modelSetTableName:(NSString*)tableName{
    [self.currentModel setObject:tableName forKey:@"tableName"];
}

-(NSString*)modelGetTableName{
    return [self.currentModel objectForKey:@"tableName"];
}


-(NSString*)modelGetPrimaryKeyName{
    int propertyCount  = [self propertyCount];
    for(int propertyIndex = 0; propertyIndex<propertyCount;propertyIndex++){
        [self propertySetCurrentByIndex:propertyIndex];
        if([self propertyGetIsKey]){
            return [self propertyGetName];
        }
    }
    return nil;
}

-(void)propertyAdd:(NSString*)propertyName{
    NSMutableDictionary* property = [self findProperty:propertyName];
    if(property==nil){
        property = [self addProperty:propertyName];
    }
    self.currentProperty = property;
}

-(NSMutableDictionary*)addProperty:(NSString*)propertyName{
    NSMutableDictionary* property = [NSMutableDictionary dictionary];
    [property setObject:propertyName forKey:@"name"];
    [property setObject:propertyName forKey:@"columnName"];
    [[self.currentModel objectForKey:@"properties"]addObject:property];
    return property;
}

-(NSString*)propertyGetName{
    return [self.currentProperty objectForKey:@"name"];
}

-(BOOL)propertySetCurrentByName:(NSString*)propertyName{
  self.currentProperty = [self findProperty:propertyName];
  return self.currentProperty != nil;
}

-(BOOL)propertySetCurrentByIndex:(int)index{
    if(index >= [self propertyCount]) return false;
    self.currentProperty = [[self.currentModel objectForKey:@"properties"]objectAtIndex:index];
    return true;
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
    [self clearPrimaryKey];
    [self.currentProperty setObject:[NSNumber numberWithBool:isKey] forKey:@"isKey"];
}

-(BOOL)propertyGetIsKey{
    return [[self.currentProperty objectForKey:@"isKey"]boolValue];
}

-(void)propertySetIsReadOnly:(BOOL)isReadOnly{
    [self.currentProperty setObject:[NSNumber numberWithBool:isReadOnly] forKey:@"isReadOnly"];
}

-(BOOL)propertyGetIsReadOnly{
    return [[self.currentProperty objectForKey:@"isReadOnly"]boolValue];
}

-(void)propertySetIgnore:(BOOL)ignore{
    [self.currentProperty setObject:[NSNumber numberWithBool:ignore] forKey:@"ignore"];
}

-(BOOL)propertyGetIgnore{
    return [[self.currentProperty objectForKey:@"ignore"]boolValue];
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
        NSMutableDictionary* property = [self findProperty:propName];
        if(property==nil){
            property = [self addProperty:propName];
            self.currentProperty = property;
            [self setupNewClassProperty:propName i:i properties:properties];
        }
        else{
            self.currentProperty = property;
        }
    }
    free(properties);
}

- (void)setupNewClassProperty:(NSString *)propName i:(int)i properties:(objc_property_t *)properties {
    if([propName caseInsensitiveCompare:
        [NSString stringWithFormat:@"%@Id",[self modelGetTableName]]]==NSOrderedSame){
        [self propertySetIsKey:true];
    }
    [self propertySetType:[self property_getTypeString:properties[i]]];
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

-(void)merge:(MODbModelMeta*)modelMeta{

    int modelsCount = [modelMeta modelCount];
    for(int modelIndex = 0; modelIndex<modelsCount;modelIndex++){
    
        [modelMeta modelSetCurrentByIndex:modelIndex];
        NSMutableDictionary*localModel = [self findModel:[modelMeta modelGetName]];
        
        if(localModel){
            int propertyCount  = [modelMeta propertyCount];
            for(int propertyIndex = 0; propertyIndex<propertyCount;propertyIndex++){
            
                [modelMeta propertySetCurrentByIndex:propertyIndex];
                
                if([self findProperty:[modelMeta propertyGetName]] == false){
                    NSMutableDictionary* property = [modelMeta performSelector:@selector(findProperty:)
                        withObject:[modelMeta propertyGetName]];
                    [[localModel objectForKey:@"properties"]addObject:property];
                }
            }
        }
        else{
            NSMutableDictionary* model = [modelMeta performSelector:@selector(findModel:)
                withObject:[modelMeta modelGetName]];
            [self.meta addObject:model];
        }
    }
}


-(NSString*)clearPrimaryKey{
   for(NSMutableDictionary *property in [self.currentModel objectForKey:@"properties"]){
        [property setObject:[NSNumber numberWithBool:false] forKey:@"isKey"];
   }
    return nil;
}

@end
