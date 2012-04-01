//
//  ProjectileEffect.m
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ProjectileEffect.h"
#import "RaidMember.h"
@interface ProjectileEffect ()
@property (nonatomic, retain) NSString *spriteName;
@property (nonatomic, retain) RaidMember *target;
@property (nonatomic, readwrite) NSTimeInterval collisionTime;
@end

@implementation ProjectileEffect
@synthesize spriteName, target, collisionTime, delay, spriteColor;
-(id)initWithSpriteName:(NSString*)sprtName target:(RaidMember*)trgt andCollisionTime:(NSTimeInterval)colTime{
    if (self=[super init]){
        self.spriteName = sprtName;
        self.target = trgt;
        self.collisionTime = colTime;
        self.spriteColor = ccWHITE;
    }
    return self;
}
@end
