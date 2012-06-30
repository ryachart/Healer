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
- (void)displaySprite:(NSString*)spriteName overRaidForDuration:(float)duration;
- (void)displayProjectileEffect:(ProjectileEffect*)effect;
- (void)displayThrowEffect:(ProjectileEffect*)effect;
- (void)displayParticleSystemWithName:(NSString*)name onTarget:(RaidMember*)target;
- (void)displayPartcileSystemOverRaidWithName:(NSString*)name;
- (void)displayPartcileSystemOnRaidWithName:(NSString*)name;
@end
