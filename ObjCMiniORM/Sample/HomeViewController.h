//
//  HomeViewController.h
//  ObjCMiniORM
//
//  Created by Kirmanie Ravariere on 10/3/12.
//  Copyright (c) 2012 Kirmanie Ravariere. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MORepository;

@interface HomeViewController : UIViewController
- (id)initWithRepository:(MORepository*)repo;
@end
