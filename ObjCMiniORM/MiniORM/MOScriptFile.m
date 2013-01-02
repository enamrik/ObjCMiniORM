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
    }
    return self;
}
-(double)timestamp{return self.scriptTimestamp;}
-(NSString*)sql{return self.sqlText;}
-(BOOL)runBeforeModelUpdate{ return false;}
@end
