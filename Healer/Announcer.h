//
//  Announcer.h
//  Healer
//
//  Created by Ryan Hart on 3/27/12.
//

#import <Foundation/Foundation.h>
#import "ProjectileEffect.h"

@class RaidMember;
@protocol Announcer <NSObject>
//Text Announcements
- (void)announce:(NSString*)announcement;
- (void)errorAnnounce:(NSString*)announcement;

//Graphical Announcements
- (void)displayScreenShakeForDuration:(float)duration;
- (void)displayScreenShakeForDuration:(float)duration afterDelay:(float)delay;
- (void)displaySprite:(NSString*)spriteName overRaidForDuration:(float)duration;
- (void)displayProjectileEffect:(ProjectileEffect*)effect;
- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target withOffset:(CGPoint)offset;
- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target withOffset:(CGPoint)offset delay:(NSTimeInterval)delay;
- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target;
- (void)displayParticleSystemOverRaidWithName:(NSString*)name;
-(void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration;
- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay;
- (void)displayParticleSystemOnRaidWithName:(NSString*)name forDuration:(float)duration offset:(CGPoint)offset;
- (void)displayParticleSystemOnRaidWithName:(NSString*)name delay:(float)delay offset:(CGPoint)offset;
- (void)displayProjectileEffect:(ProjectileEffect*)effect fromOrigin:(CGPoint)origin;
- (void)displayBreathEffectOnRaidForDuration:(float)duration;

- (void)displayEnergyGainFrom:(RaidMember*)member;
- (void)displayAttackFromRaidMember:(RaidMember*)member;

- (void)displayCriticalPlayerDamage;
@end
