//
//  CollectibleLayer.m
//  Healer
//
//  Created by Ryan Hart on 4/22/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CollectibleLayer.h"
#import "Collectible.h"
#import "Encounter.h"

@implementation CollectibleSprite
- (void)dealloc
{
    [_collectible release];
    [super dealloc];
}

- (void)complete
{
    [self stopAllActions];
    
    CCActionInterval *firstAction = nil;
    
    if (self.collectible.isActivated) {
        firstAction = [CCSpawn actionOne:[CCScaleTo actionWithDuration:.33 scale:2.0] two:[CCFadeTo actionWithDuration:.33 opacity:0]];
    } else {
        firstAction = [CCSpawn actionOne:[CCScaleTo actionWithDuration:.33 scale:0.0] two:[CCFadeTo actionWithDuration:.33 opacity:0]];
    }
    
    [self runAction:[CCSequence actions:firstAction, [CCCallBlockN actionWithBlock:^(CCNode *node){[node removeFromParentAndCleanup:YES];}], nil]];
}


- (void)beginMovement
{
    if (self.collectible.movementType == CollectibleMovementTypeFloat) {
        CCRepeatForever *floatAction = [CCRepeatForever actionWithAction:
                                        [CCSequence actions:
                                         [CCMoveBy actionWithDuration:1.0 position:self.collectible.movementVector],
                                         [CCMoveBy actionWithDuration:1.0 position:CGPointMake(-self.collectible.movementVector.x, -self.collectible.movementVector.y)], nil]];
        [self runAction:floatAction];
    }
}
@end

@interface CollectibleLayer ()
@property (nonatomic, retain) NSMutableArray *collectibles;
@end

@implementation CollectibleLayer

- (void)dealloc
{
    [_collectibles release];
    [_owningPlayer release];
    [_encounter release];
    [_players release];
    [super dealloc];
}

- (id)initWithOwningPlayer:(Player*)player encounter:(Encounter*)enc players:(NSArray*)players
{
    if (self = [super init]) {
        self.isTouchEnabled = YES;
        self.collectibles = [NSMutableArray arrayWithCapacity:10];
        self.owningPlayer = player;
        self.encounter = enc;
        self.players = players;
    }
    return self;
}

- (void)addCollectible:(Collectible *)collectible
{
    CollectibleSprite *colSprite = [CollectibleSprite spriteWithSpriteFrameName:collectible.spriteName];
    [colSprite setCollectible:collectible];
    [colSprite setPosition:CGPointMake(512, 500)];
//    [colSprite setOpacity:0];
    [self addChild:colSprite z:5];
    [self.collectibles addObject:colSprite];
    
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:2];
    
    NSTimeInterval delay = (arc4random() % 250) / 1000.0;
//    CCDelayTime *randomDelay = [CCDelayTime actionWithDuration:delay];
//    [actions addObject:randomDelay];
    
    if (collectible.entranceType == CollectibleEntranceTypeFall) {
        
    } else if (collectible.entranceType == CollectibleEntranceTypeSpew) {
        NSInteger randomWidth = (arc4random() % 2 ? 1 : -1) * (arc4random() % 300);
        CCJumpBy *spewAction = [CCJumpBy actionWithDuration:.33 + delay position:CGPointMake(randomWidth, -140) height:50 jumps:1];
        [actions addObject:spewAction];
    }
    
//    CCFadeTo *fadeIn = [CCFadeTo actionWithDuration:0 opacity:255];
//    [actions addObject:fadeIn];
    
    collectible.duration += delay;
    
    CCCallFunc *beginMove = [CCCallFunc actionWithTarget:colSprite selector:@selector(beginMovement)];
    [actions addObject:beginMove];
    
    CCSequence *entranceAndMovement = [CCSequence actionWithArray:actions];
    [colSprite runAction:entranceAndMovement];
    
}

- (void)updateAllCollectibles:(NSTimeInterval)deltaT
{
    NSMutableArray *removeCollectibles = [NSMutableArray arrayWithCapacity:self.collectibles.count];
    for (CollectibleSprite *sprite in self.collectibles) {
        [sprite.collectible updateForTimeInterval:deltaT];
        if ([sprite.collectible isExpired]) {
            if (!sprite.collectible.isActivated) {
                [sprite complete];
                [sprite.collectible expireForRaid:self.encounter.raid players:self.players enemies:self.encounter.enemies];
            }
            [removeCollectibles addObject:sprite];
        }
    }
    
    for (CollectibleSprite *colSprite in removeCollectibles) {
        [self.collectibles removeObject:colSprite];
    }
}

- (void)removeAllCollectibles
{
    for (CollectibleSprite *sprite in self.collectibles) {
        [sprite removeFromParentAndCleanup:YES];
    }
    [self.collectibles removeAllObjects];
}

#pragma mark - Touch handling
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isPaused) return;
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    for (CollectibleSprite * sprite in self.collectibles) {
        if (!sprite.collectible.isExpired && CGRectContainsPoint(sprite.boundingBox, convertedToNodeSpacePoint)){
            [sprite.collectible activateByPlayer:self.owningPlayer forRaid:self.encounter.raid players:self.players enemies:self.encounter.enemies];
            [sprite complete];
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isPaused) return;
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    CGRect layerRect =  [self boundingBox];
    layerRect.origin = CGPointZero;
    CGPoint convertedToNodeSpacePoint = [self convertToNodeSpace:touchLocation];
    
    for (CollectibleSprite * sprite in self.collectibles) {
        if (!sprite.collectible.isExpired && CGRectContainsPoint(sprite.boundingBox, convertedToNodeSpacePoint)){
            [sprite.collectible activateByPlayer:self.owningPlayer forRaid:self.encounter.raid players:self.players enemies:self.encounter.enemies];
            [sprite complete];
        }
    }
}
@end
