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
@property (copy) NSString*sqlText;
-(double)timestamp;
-(NSString*)sql;
-(BOOL)runBeforeModelUpdate;
@end
