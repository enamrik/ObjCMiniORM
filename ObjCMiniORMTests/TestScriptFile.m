//
//  TestScriptFile.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/10/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "TestScriptFile.h"

@interface TestScriptFile(){
    NSString* _sql;
    double _timestamp;
    BOOL _beforeModelUpdate;
}
@end

@implementation TestScriptFile


-(id)initWithTimestamp:(double)timestamp andSql:(NSString*)sql{
    self=[super init];
    if (self) {
        _sql = [sql copy];
        _timestamp = timestamp;
        _beforeModelUpdate = false;
    }
    return self;
}

-(id)initWithTimestamp:(double)timestamp andSql:(NSString*)sql beforeModelUpdate:(BOOL)before{
    self=[self initWithTimestamp:timestamp andSql:sql];
    if (self) {
        _beforeModelUpdate = before;
    }
    return self;
}

-(BOOL)runBeforeModelUpdate{
    return _beforeModelUpdate;
}

-(double)timestamp{
    return _timestamp;
}
-(NSString*)sql{
    return _sql;
}

@end
