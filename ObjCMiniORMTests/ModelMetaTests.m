//
//  ModelMetaTests.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/10/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "ModelMetaTests.h"
#import "MODbModelMeta.h"
#import "TestModel.h"

@implementation ModelMetaTests

-(void)testWillAddModelByName{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    
    STAssertTrue([meta modelCount]==1, @"WillAddModelByName -  has model");
    STAssertTrue([[meta modelGetName]isEqualToString:@"MyModel"],
        @"WillAddModelByName -  has model");
}

-(void)testWillAddModelByType{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByType:TestModel.class];
    
    STAssertTrue([meta modelCount]==1, @"WillAddModelByType -  has model");
    STAssertTrue([[meta modelGetName]isEqualToString:@"TestModel"],
        @"WillAddModelByType -  has model");
}

-(void)testWillSetCurrentModelByName{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByType:TestModel.class];
    [meta modelAddByName:@"MyModel"];
    [meta modelSetCurrentByName:@"TestModel"];
    STAssertTrue([[meta modelGetName]isEqualToString:@"TestModel"], @"WillSetCurrentModelByName");
}

-(void)testWillSetModelProperties{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    [meta modelSetTableName:@"ATable"];
    STAssertTrue([[meta modelGetTableName]isEqualToString:@"ATable"], @"WillSetModelProperties");
}

-(void)testWillSetModelPropertyDefaults{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    STAssertTrue([[meta modelGetTableName]isEqualToString:@"MyModel"], @"WillSetModelProperties");
}

-(void)testWillAddProperty{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    [meta propertyAdd:@"MyModelId"];
    [meta propertySetIsKey:true];
    [meta propertyAdd:@"MyModelName"];
    
    STAssertTrue([meta propertyCount]==2, @"WillAddProperty -  has model");
    [meta propertySetCurrentByIndex:0];
    STAssertTrue([[meta propertyGetName]isEqualToString:@"MyModelId"],@"WillAddProperty -  has model");
    [meta propertySetCurrentByIndex:1];
    STAssertTrue([[meta propertyGetName]isEqualToString:@"MyModelName"],@"WillAddProperty -  has model");
}

-(void)testWillSetCurrentPropertyByName{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    [meta propertyAdd:@"MyModelId"];
    [meta propertySetIsKey:true];
    [meta propertyAdd:@"MyModelName"];
    
    [meta propertySetCurrentByName:@"MyModelId"];
    STAssertTrue([[meta propertyGetName]isEqualToString:@"MyModelId"], @"WillSetCurrentPropertyByName");
}

-(void)testWillSetPropertyProperties{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    [meta propertyAdd:@"MyModelId"];
    [meta propertySetIsKey:true];
    [meta propertySetColumnName:@"MyColumn"];
    
    STAssertTrue([[meta propertyGetColumnName]isEqualToString:@"MyColumn"], @"WillSetPropertyProperties");
    STAssertTrue([meta propertyGetIsKey], @"WillSetPropertyProperties");
}

-(void)testWillSetPropertyPropertiesDefaults{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByName:@"MyModel"];
    [meta propertyAdd:@"MyModelId"];

    STAssertTrue([[meta propertyGetColumnName]isEqualToString:@"MyModelId"], @"WillSetPropertyProperties");
    STAssertTrue([meta propertyGetIsKey]==false, @"WillSetPropertyProperties");
}

-(void)testWillAutoGenPropertiesIfModelAddedByType{
    MODbModelMeta *meta = [[[MODbModelMeta alloc]init]autorelease];
    [meta modelAddByType:TestModel.class];
    [meta propertySetCurrentByName:@"fullName"];
    STAssertTrue([[meta propertyGetName]isEqualToString:@"fullName"], @"WillSetCurrentModelByName");
}

@end
