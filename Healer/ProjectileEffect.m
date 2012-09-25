//
//  ProjectileEffect.m
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import "ProjectileEffect.h"
#import "RaidMember.h"
#import "Raid.h"
@interface ProjectileEffect ()
@property (nonatomic, retain) NSString *spriteName;
@property (nonatomic, retain) RaidMember *target;
@property (nonatomic, readwrite) NSTimeInterval collisionTime;
@end

@implementation ProjectileEffect
@synthesize spriteName, target, collisionTime, delay, spriteColor, collisionParticleName, type;

- (void)dealloc {
    [collisionParticleName release];
    [target release];
    [spriteName release];
    [super dealloc];
}

-(id)initWithSpriteName:(NSString*)sprtName target:(RaidMember*)trgt andCollisionTime:(NSTimeInterval)colTime{
    if (self=[super init]){
        self.spriteName = sprtName;
        self.target = trgt;
        self.collisionTime = colTime;
        self.spriteColor = ccWHITE;
        self.isFailed = NO;
    }
    return self;
}

//PRTEFF|TARGET|SPRITE|COLPARTNAME|R|G|B|TIME|TYPE|isFailed
-(NSString*)asNetworkMessage{
    return [NSString stringWithFormat:@"PRJEFF|%@|%@|%@|%i|%i|%i|%f|%i|%i", target.battleID, spriteName, self.collisionParticleName, spriteColor.r, spriteColor.g, spriteColor.b, collisionTime + delay, type, self.isFailed];
}

-(id)initWithNetworkMessage:(NSString*)message andRaid:(Raid*)raid{
    if (self=[super init]){
        NSArray *components = [message componentsSeparatedByString:@"|"];
        
        if (components.count < 10){
            NSLog(@"MALFORMED PROJECTILE MESSAGE");
        }
        self.target = [raid memberForBattleID:[components objectAtIndex:1]];
        self.collisionParticleName = [components objectAtIndex:3];
        self.spriteName = [components objectAtIndex:2];
        self.spriteColor = ccc3([[components objectAtIndex:4] intValue], [[components objectAtIndex:5] intValue], [[components objectAtIndex:6] intValue]);
        self.collisionTime = [[components objectAtIndex:7] floatValue];
        self.type = [[components objectAtIndex:8] intValue];
        self.isFailed = [[components objectAtIndex:9] boolValue];
    }
    return self;
}
@end
