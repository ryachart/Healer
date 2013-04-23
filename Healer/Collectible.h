//
//  Collectible.h
//  Healer
//
//  Created by Ryan Hart on 4/22/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CollectibleMovementTypeStatic,
    CollectibleMovementTypeFloat
} CollectibleMovementType;

typedef enum {
    CollectibleEntranceTypeAppear,
    CollectibleEntranceTypeSpew,
    CollectibleEntranceTypeFall
} CollectibleEntranceType;

@class Collectible, Player, Raid;
@protocol CollectibleDelegate <NSObject>
- (void)collectible:(Collectible*)col wasCollectedByPlayer:(Player*)player forRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;
- (void)collectibleDidExpire:(Collectible*)col forRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;
@end

@interface Collectible : NSObject
@property (nonatomic, retain) NSString *spriteName;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval timeApplied;
@property (nonatomic, readwrite) CGPoint movementVector;
@property (nonatomic, readonly) BOOL isExpired;
@property (nonatomic, readonly) BOOL isActivated;
@property (nonatomic, readwrite) CollectibleEntranceType entranceType;
@property (nonatomic, readwrite) CollectibleMovementType movementType;

- (id)initWithSpriteName:(NSString *)spriteName andDuration:(NSTimeInterval)duration;
- (void)registerDelegate:(id<CollectibleDelegate>)delegate;

- (void)activateByPlayer:(Player*)player forRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;
- (void)expireForRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies;

- (void)updateForTimeInterval:(NSTimeInterval)deltaT;
@end