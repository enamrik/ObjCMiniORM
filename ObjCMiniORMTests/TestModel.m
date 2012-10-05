//
//  TestModel.m
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/4/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import "TestModel.h"

@implementation TestModel

-(void)dealloc{
    self.fullName=nil;
    self.modelDate=nil;
    [super dealloc];
}
@end
