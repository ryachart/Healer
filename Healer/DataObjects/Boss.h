//
//  Boss.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CombatEvent.h"
#import "Announcer.h"
@class Player;
@class Raid;
@class RaidMember;
@class Effect;
/*A collection of data regarding a boss.
  To make special bosses, subclass boss and override
  combatActions.
 */
@interface Boss : NSObject <EventDataSource> {
	NSInteger health;
	NSInteger maximumHealth;
	NSInteger damage;
	NSInteger targets;
	float frequency;
	BOOL choosesMainTank;
	NSString *title;
	
	//Combat Action Data
}
@property (nonatomic, retain) id <Announcer> announcer;
@property (nonatomic, setter=setHealth:) NSInteger health;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, assign) id<EventLogger> logger;
@property NSInteger maximumHealth;

@property (nonatomic, readwrite) float lastAttack;

-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses;
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)timeDelta;
-(void)setHealth:(NSInteger)newHealth;
-(BOOL)isDead;
+(id)defaultBoss;
@end


#pragma mark - Shipping Bosses
@interface Ghoul : Boss
@end

@interface Troll : Boss
@end

@interface Drake : Boss
@end

@interface Trulzar : Boss
@end

@interface DarkCouncil : Boss
@end




#pragma mark -
#pragma mark Demo Bosses
@interface Dragon : Boss {

}
+(id)defaultBoss;
@end

@interface Giant: Boss {
}
+(id)defaultBoss;
@end

@interface Hydra : Boss
{
		
}

+(id)defaultBoss;

@end

@interface ChaosDemon : Boss
{
	NSInteger numEnrages;
	Effect *currentFireball;
}
@property NSInteger numEnrages;
+(id)defaultBoss;
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(float)theTime;

@end

#pragma mark -
#pragma mark Campaign Bosses
@interface MinorDemon : Boss
{
		
}
@end

@interface FieryDemon : Boss
{
	Effect *currentFireball;
}

@end

@interface BringerOfEvil : Boss
{
	NSInteger numEnrages;
	Effect *currentFireball;
}
@property NSInteger numEnrages;
@end