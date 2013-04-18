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
@class Agent;

typedef enum {
    ProjectileEffectTypeNormal, 
    ProjectileEffectTypeThrow,
} ProjectileEffectType;

@interface ProjectileEffect : NSObject
@property (nonatomic, readwrite) ProjectileEffectType type;
@property (nonatomic, assign) Agent *sourceAgent;
@property (nonatomic, retain) NSString* collisionParticleName;
@property (nonatomic, retain) NSString* collisionSoundName;
@property (nonatomic, readonly, retain) NSString *spriteName;
@property (nonatomic, readonly, retain) Agent *target;
@property (nonatomic, readonly) NSTimeInterval collisionTime;
@property (nonatomic, readwrite) ccColor3B spriteColor;
@property (nonatomic, readwrite) NSTimeInterval delay;
@property (nonatomic, readwrite) BOOL isFailed;
@property (nonatomic, readwrite) NSInteger frameCount;

-(id)initWithSpriteName:(NSString*)spriteName target:(Agent*)target collisionTime:(NSTimeInterval)colTime sourceAgent:(Agent*)source;
-(id)initWithNetworkMessage:(NSString*)message raid:(Raid*)raid enemies:(NSArray*)enemies;
//PRTEFF|TARGET|SPRITE|R|G|B|TIME|TYPE
-(NSString*)asNetworkMessage;
@end
