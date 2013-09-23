//
//  Collectible.m
//  Healer
//
//  Created by Ryan Hart on 4/22/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "Collectible.h"

@interface Collectible ()
@property (nonatomic, readwrite) BOOL isActivated;
@property (nonatomic, retain) NSMutableArray *delegates;
@property (nonatomic, readwrite) NSTimeInterval timeApplied;
@end

@implementation Collectible

- (void)dealloc
{
    [_delegates release];
    [_spriteName release];
    [super dealloc];
}

- (id)initWithSpriteName:(NSString *)spriteName andDuration:(NSTimeInterval)duration
{
    if (self = [super init]) {
        self.spriteName = spriteName;
        self.duration = duration;
        self.delegates = [NSMutableArray arrayWithCapacity:5];
        self.timeApplied = 0;
        self.scale = 1.0;
    }
    return self;
}

- (BOOL)isExpired
{
    return self.timeApplied >= self.duration || self.isActivated;
}

- (void)activateByPlayer:(Player *)player forRaid:(Raid *)theRaid players:(NSArray *)players enemies:(NSArray *)enemies
{
    if (!self.isActivated) {
        for (id<CollectibleDelegate>delegate in self.delegates) {
            [delegate collectible:self wasCollectedByPlayer:player forRaid:theRaid players:players enemies:enemies];
        }
        self.isActivated = YES;
    }
}

- (void)expireForRaid:(Raid*)theRaid players:(NSArray*)players enemies:(NSArray*)enemies
{
    for (id<CollectibleDelegate>delegate in self.delegates) {
        [delegate collectibleDidExpire:self forRaid:theRaid players:players enemies:enemies];
    }
}

- (void)updateForTimeInterval:(NSTimeInterval)deltaT
{
    self.timeApplied += deltaT;
}

- (void)registerDelegate:(id<CollectibleDelegate>)delegate
{
    [self.delegates addObject:delegate];
}

@end
