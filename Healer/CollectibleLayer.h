//
//  CollectibleLayer.h
//  Healer
//
//  Created by Ryan Hart on 4/22/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"

@class Collectible, Player, Encounter;

@interface CollectibleSprite : CCSprite
@property (nonatomic, retain) Collectible *collectible;
- (void)complete;
@end

@interface CollectibleLayer : CCLayer
@property (nonatomic, retain) Player *owningPlayer;
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, retain) NSArray *players;
@property (nonatomic, readwrite) BOOL isPaused;
- (id)initWithOwningPlayer:(Player*)player encounter:(Encounter*)enc players:(NSArray*)players;
- (void)addCollectible:(Collectible*)collectible;
- (void)removeAllCollectibles;

- (void)updateAllCollectibles:(NSTimeInterval)deltaT;
@end
