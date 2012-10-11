//
//  TestScriptFile.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/10/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MODbMigrator.h"

@interface TestScriptFile : NSObject<IScriptFile>
-(id)initWithTimestamp:(double)timestamp andSql:(NSString*)sql;
-(id)initWithTimestamp:(double)timestamp andSql:(NSString*)sql beforeModelUpdate:(BOOL)before;
-(BOOL)runBeforeModelUpdate;
-(double)timestamp;
-(NSString*)sql;
@end
