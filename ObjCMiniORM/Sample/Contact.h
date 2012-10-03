//
//  Contact.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/3/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject
@property int contactId;//primary key must be an integer and must be in the convention <table-name>id
@property(copy)NSString*fullName;
@property(strong)NSDate* addedOn;
@end
