//
//  Container.h
//  RaidLeader
//
//  Created by Ryan Hart on 11/6/10.
//  Copyright 2010 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol Container

-(void)dropObjectIntoContainer:(id)obj;
-(void)emptyContainer;

@end
