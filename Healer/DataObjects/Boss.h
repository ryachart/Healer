//
//  Boss.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Player;
@class Raid;
@class RaidMember;
@class Effect;
/*A collection of data regarding a boss.
  To make special bosses, subclass boss and override
  combatActions.
 */
@interface Boss : NSObject {
	NSInteger health;
	NSInteger maximumHealth;
	NSInteger damage;
	NSInteger targets;
	float frequency;
	BOOL choosesMainTank;
	NSString *title;
	
	//Combat Action Data
	NSDate *lastAttack;
}
@property (nonatomic, setter=setHealth:) NSInteger health;
@property (nonatomic, retain) NSString* title;
@property NSInteger maximumHealth;

@property (nonatomic, copy) NSDate *lastAttack;
-(id)initWithHealth:(NSInteger)hlth damage:(NSInteger)dmg targets:(NSInteger)trgets frequency:(float)freq andChoosesMT:(BOOL)chooses;
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime;
-(void)setHealth:(NSInteger)newHealth;
-(BOOL)isDead;
+(id)defaultBoss;
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
-(void) combatActions:(Player*)player theRaid:(Raid*)theRaid gameTime:(NSDate*)theTime;

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