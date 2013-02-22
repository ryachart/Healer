//
//  BossHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BossHealthView.h"
#import "ClippingNode.h"
#import "BossCastBar.h"

#define HEALTH_INSET_WIDTH 6.0
#define HEALTH_INSET_HEIGHT 45.0

@interface BossHealthView ()
@property (nonatomic, assign) ClippingNode *bossHealthBack;
@property (nonatomic, readwrite) NSInteger lastHealth;
@property (nonatomic, assign) CCSprite *portraitSprite;
@property (nonatomic, assign) CCSprite *bossPlateSprite;
@property (nonatomic, assign) BossCastBar *castBar;
@end

@implementation BossHealthView

- (id)initWithFrame:(CGRect)frame andBossKey:(NSString *)bossKey {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        
        self.castBar = [[[BossCastBar alloc] initWithFrame:CGRectMake(48, -38, 0, 0)] autorelease];
        self.castBar.scale = .70;
        self.castBar.opacity = 0;
        [self addChild:self.castBar z:100];

        self.portraitSprite = [CCSprite spriteWithSpriteFrameName:@"boss_portrait_back.png"];
        [self.portraitSprite setPosition:CGPointMake(736, 20)];
        [self addChild:self.portraitSprite z:10];
        
        CCSpriteFrame *bossPortraitFrame = nil;
        
        if (bossKey) {
            bossPortraitFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"%@_battle_portrait.png", bossKey]];
        }
        if (!bossPortraitFrame) {
            bossPortraitFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"boss_default.png"];
        }
        
        CCSprite *portrait = [CCSprite spriteWithSpriteFrame:bossPortraitFrame];
        [portrait setPosition:CGPointMake(84,84)];
        [self.portraitSprite addChild:portrait];
        
        
        self.lastHealth = 0;
        
        self.bossPlateSprite = [CCSprite spriteWithSpriteFrameName:@"boss_plate.png"];
        [self.bossPlateSprite setAnchorPoint:CGPointZero];
        [self addChild:self.bossPlateSprite];
        
        CCSprite *healthBar = [CCSprite spriteWithSpriteFrameName:@"boss_health_back.png"];
        
        self.bossHealthBack = [ClippingNode node];
        [self.bossHealthBack setAnchorPoint:CGPointZero];
        [self.bossHealthBack setContentSize:healthBar.contentSize];
        [self.bossHealthBack setClippingRegion:CGRectMake(HEALTH_INSET_WIDTH,HEALTH_INSET_HEIGHT, healthBar.contentSize.width, healthBar.contentSize.height)];
        [healthBar setAnchorPoint:ccp(0,0)];
        [healthBar setPosition:CGPointMake(HEALTH_INSET_WIDTH, HEALTH_INSET_HEIGHT)];
        [self.bossHealthBack addChild:healthBar z:1];
        
        self.bossNameLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(280, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold" fontSize:32.0];
        self.bossNameLabel.position = CGPointMake(510, 14);
        [self.bossNameLabel setColor:ccc3(220, 220, 220)];
        
        self.healthLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold"  fontSize:32.0];
        [self.healthLabel setColor:ccc3(230, 230, 230)];
        [self.healthLabel setPosition:CGPointMake(300, 60)];
        
        
        [self addChild:self.bossHealthBack];
        [self addChild:self.bossNameLabel z:10];
        [self addChild:self.healthLabel z:10];
    }
    return self;
}



-(void)setBossData:(Enemy*)theBoss
{
	_bossData = theBoss;
	
	[self.bossNameLabel setString:[_bossData namePlateTitle]];
	self.lastHealth = theBoss.health;
    
    [self.abilityDescriptionsView removeFromParentAndCleanup:YES];
    self.abilityDescriptionsView = [[[BossAbilityDescriptionsView alloc] initWithBoss:self.bossData] autorelease];
    [self.abilityDescriptionsView setAnchorPoint:CGPointZero];
    [self.abilityDescriptionsView setPosition:CGPointMake(-398, -304)];
    [self.abilityDescriptionsView setDelegate:self];
    [self addChild:self.abilityDescriptionsView];
    
    [self.castBar setBoss:theBoss];
	
}

-(void)updateHealth
{
    if (self.bossData && self.bossData.health < self.lastHealth){
        int startingFuzzX = arc4random() % 20 + self.bossHealthBack.clippingRegion.origin.x + self.bossHealthBack.clippingRegion.size.width ;
        int startingFuzzY = arc4random() % 20;
        int heal = self.bossData.health - self.lastHealth;
        
        CCLabelTTF *sctLabel = [CCLabelTTFShadow labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [sctLabel setColor:ccRED];
        [sctLabel setPosition:CGPointMake(startingFuzzX, self.contentSize.height + startingFuzzY)];
        
        [self addChild:sctLabel z:11];
        
        int direction = arc4random() % 2 == 1 ? -1 : 1;
        int distanceFuzz = arc4random() % 50;
        [sctLabel runAction:[CCSequence actions:[CCSpawn actions:[CCJumpBy actionWithDuration:2.0 position:CGPointMake(direction * 50 + distanceFuzz, -50) height:20 jumps:1], [CCFadeTo actionWithDuration:2.0 opacity:0], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];}], nil]];
    }
    
    self.lastHealth = self.bossData.health;
	NSString *healthText;
	if (self.bossData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f%%", (((float)self.bossData.health) / self.bossData.maximumHealth)*100];
	}
	else {
		healthText = @"Dead";
	}
	
	if (![healthText isEqualToString:[self.healthLabel string]]){
		[self.healthLabel setString:healthText];
	}
    
    [self.bossNameLabel setString:[self.bossData namePlateTitle]];
    
    double percentageOfHealth = ((float)[self.bossData health])/[self.bossData maximumHealth];
    [self.bossHealthBack setClippingRegion:CGRectMake(HEALTH_INSET_WIDTH-(self.bossHealthBack.clippingRegion.size.width * (1 - percentageOfHealth)), self.bossHealthBack.clippingRegion.origin.y, self.bossHealthBack.clippingRegion.size.width, self.bossHealthBack.clippingRegion.size.height)];
    
    [self.abilityDescriptionsView update];
    [self.castBar update];
}

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor *)descriptor {
    [self.delegate bossHealthViewShouldDisplayAbility:descriptor];
}

- (void)endBattleWithSuccess:(BOOL)success
{
    [self.bossHealthBack runAction:[CCFadeOut actionWithDuration:3.0]];
    [self.bossNameLabel runAction:[CCFadeOut actionWithDuration:3.0]];
    [self.bossPlateSprite runAction:[CCFadeOut actionWithDuration:3.0]];
    [self.healthLabel runAction:[CCFadeOut actionWithDuration:3.0]];
    [self.abilityDescriptionsView runAction:[CCFadeOut actionWithDuration:3.0]];
    
    CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Marion-Bold" fontSize:72.0];
    [victoryLabel setColor:ccBLACK];
    [victoryLabel setPosition:[self convertToNodeSpace:CGPointMake(512, 500)]];
    [victoryLabel setScale:2.0];
    [victoryLabel setOpacity:0];
    [self addChild:victoryLabel];
    [victoryLabel runAction:[CCSequence actions:[CCDelayTime actionWithDuration:2.75],[CCSpawn actions:[CCScaleTo actionWithDuration:.5 scale:1.0], [CCFadeIn actionWithDuration:1.0], nil], nil]];
    
    if (success) {
        CGPoint destination = [self convertToNodeSpace:CGPointMake(512, 320)];
        [self.portraitSprite runAction:[CCSequence actions:[CCMoveTo actionWithDuration:2.5 position:destination],[CCDelayTime actionWithDuration:1.0] ,[CCSpawn actionOne:[CCFadeOut actionWithDuration:1.5] two:[CCScaleTo actionWithDuration:1.5]], nil]];
    } else {
        victoryLabel.string = @"DEFEAT!";
    }
}

- (void)dealloc {
    [_bossNameLabel release];
    [_healthLabel release];
    [super dealloc];
}


@end
