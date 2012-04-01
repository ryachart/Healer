//
//  ProjectileEffect.h
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class RaidMember;
@interface ProjectileEffect : NSObject
@property (nonatomic, readonly, retain) NSString *spriteName;
@property (nonatomic, readonly, retain) RaidMember *target;
@property (nonatomic, readonly) NSTimeInterval collisionTime;
@property (nonatomic, readwrite) ccColor3B spriteColor;
@property (nonatomic, readwrite) NSTimeInterval delay;
-(id)initWithSpriteName:(NSString*)spriteName target:(RaidMember*)target andCollisionTime:(NSTimeInterval)colTime;
@end
