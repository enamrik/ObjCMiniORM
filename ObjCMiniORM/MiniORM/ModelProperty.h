//
//  ModelProperty.h
//  CoreMeetingViewer
//
//  Created by Kirmanie Ravariere on 1/22/12.
//  Copyright (c) 2012 GeoNorth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelProperty : NSObject

@property(nonatomic,retain)NSString *propertyName;
@property(nonatomic,retain)NSString *propertyType;
@property BOOL isReadOnly;
@property(nonatomic,retain)NSString *propertyDbName;
@end
