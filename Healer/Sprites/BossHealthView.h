//
//  BossHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "cocos2d.h"
#import "BossAbilityDescriptionsView.h"

@protocol BossHealthViewDelegate <NSObject>

- (void)bossHealthViewShouldDisplayAbility:(AbilityDescriptor*)ability;

@end

@interface BossHealthView : CCLayer <AbilityDescriptionViewDelegate>
@property (nonatomic, assign) id <BossHealthViewDelegate> delegate;
@property (nonatomic, assign, setter=setBossData:) Boss* bossData;
@property (nonatomic, retain) CCLabelTTF *bossNameLabel;
@property (nonatomic, retain) CCLabelTTF *healthLabel;
@property (nonatomic, assign) BossAbilityDescriptionsView* abilityDescriptionsView;

- (void)setBossData:(Boss*)theBoss;
- (id)initWithFrame:(CGRect)frame andBossKey:(NSString *)bossKey;
- (void)updateHealth;
- (void)endBattleWithSuccess:(BOOL)success;
@end
