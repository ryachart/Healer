//
//  ProjectileEffect.h
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class RaidMember;
@class Raid;
typedef enum {
    ProjectileEffectTypeNormal, 
    ProjectileEffectTypeThrow,
} ProjectileEffectType;

@interface ProjectileEffect : NSObject
@property (nonatomic, readwrite) ProjectileEffectType type;
@property (nonatomic, retain) NSString* collisionParticleName;
@property (nonatomic, readonly, retain) NSString *spriteName;
@property (nonatomic, readonly, retain) RaidMember *target;
@property (nonatomic, readonly) NSTimeInterval collisionTime;
@property (nonatomic, readwrite) ccColor3B spriteColor;
@property (nonatomic, readwrite) NSTimeInterval delay;

-(id)initWithSpriteName:(NSString*)spriteName target:(RaidMember*)target andCollisionTime:(NSTimeInterval)colTime;
-(id)initWithNetworkMessage:(NSString*)message andRaid:(Raid*)raid;
//PRTEFF|TARGET|SPRITE|R|G|B|TIME|TYPE
-(NSString*)asNetworkMessage;
@end
