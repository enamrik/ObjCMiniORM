//
//  ModelProperty.m
//  CoreMeetingViewer
//
//  Created by Kirmanie Ravariere on 1/22/12.
//  Copyright (c) 2012 GeoNorth. All rights reserved.
//

#import "ModelProperty.h"

@implementation ModelProperty

@synthesize propertyName,propertyType,isReadOnly,propertyDbName;

- (void)dealloc {
    self.propertyDbName=nil;
    self.propertyName=nil;
    self.propertyType=nil;
    [super dealloc];
}
@end
