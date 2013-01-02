//
//  MOScriptFile.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 1/1/13.
//  Copyright (c) 2013 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MODbMigrator.h"

@interface MOScriptFile : NSObject<IScriptFile>
@property double scriptTimestamp;
@property (strong) NSMutableArray*sqlText;
-(id)initWithTimestamp:(int)tm andSql:(NSString*)sql;
-(double)timestamp;
-(NSMutableArray*)sqlStatements;
-(BOOL)runBeforeModelUpdate;
-(void)addStatement:(NSString*)sql;
@end
