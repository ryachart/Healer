//
//  ProjectileEffect.m
//  Healer
//
//  Created by Ryan Hart on 3/30/12.
//

#import "ProjectileEffect.h"
#import "RaidMember.h"
#import "Raid.h"
#import "Enemy.h"

@interface ProjectileEffect ()
@property (nonatomic, retain) NSString *spriteName;
@property (nonatomic, retain) Agent *target;
@property (nonatomic, readwrite) NSTimeInterval collisionTime;
@end

@implementation ProjectileEffect

- (void)dealloc {
    [_collisionParticleName release];
    [_target release];
    [_spriteName release];
    [super dealloc];
}

-(id)initWithSpriteName:(NSString*)spriteName target:(Agent*)target collisionTime:(NSTimeInterval)colTime sourceAgent:(Agent*)source {
    if (self=[super init]){
        self.spriteName = spriteName;
        self.target = target;
        self.collisionTime = colTime;
        self.spriteColor = ccWHITE;
        self.isFailed = NO;
        self.sourceAgent = source;
    }
    return self;
}

//PRTEFF|TARGET|SPRITE|COLPARTNAME|R|G|B|TIME|TYPE|isFailed
-(NSString*)asNetworkMessage{
    return [NSString stringWithFormat:@"PRJEFF|%@|%@|%@|%i|%i|%i|%f|%i|%i|%@|%i", ((RaidMember*)self.target).networkId, self.spriteName, self.collisionParticleName, self.spriteColor.r, self.spriteColor.g, self.spriteColor.b, self.collisionTime + self.delay, self.type, self.isFailed, self.sourceAgent.networkID, self.frameCount];
}

-(id)initWithNetworkMessage:(NSString*)message raid:(Raid*)raid enemies:(NSArray *)enemies{
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
        
        for (Agent *agent in [enemies arrayByAddingObjectsFromArray:raid.members   ]) {
            if ([agent.networkID isEqualToString:[components objectAtIndex:10]]) {
                self.sourceAgent = agent;
                break;
            }
        }
        
        self.frameCount = [[components objectAtIndex:11] intValue];
    }
    return self;
}
@end
