//
//  MOScriptFile.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 1/1/13.
//  Copyright (c) 2013 Kirmanie Ravariere. All rights reserved.
//

#import "MOScriptFile.h"

@implementation MOScriptFile
@synthesize scriptTimestamp,sqlText;
-(id)init{
    self=[super init];
    if (self) {
        self.scriptTimestamp = [[NSDate date] timeIntervalSince1970];
        self.sqlText = [NSMutableArray array];
    }
    return self;
}

-(id)initWithTimestamp:(int)tm andSql:(NSString*)sql{
    self=[super init];
    if (self) {
        self.scriptTimestamp = tm;
        self.sqlText = [NSMutableArray array];
        [self.sqlText addObject:sql];
    }
    return self;
}

-(void)addStatement:(NSString*)sql{
    [self.sqlText addObject:sql];
}

-(double)timestamp{return self.scriptTimestamp;}
-(NSMutableArray*)sqlStatements{return self.sqlText;}
-(BOOL)runBeforeModelUpdate{ return false;}
@end
