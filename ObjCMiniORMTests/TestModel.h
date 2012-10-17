//
//  TestModel.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/4/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestModel : NSObject
@property int testModelId;
@property(copy)NSString*fullName;
@property(copy)NSString* readonlyProperty;
@property(copy)NSString* ignoreProperty;
@property(strong)NSDate *modelDate;
@end
