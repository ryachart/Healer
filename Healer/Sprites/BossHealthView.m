//
//  BossHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BossHealthView.h"
#import "ClippingNode.h"

#define HEALTH_INSET_WIDTH 6.0
#define HEALTH_INSET_HEIGHT 45.0

@interface BossHealthView ()
@property (nonatomic, assign) ClippingNode *bossHealthBack;
@property (nonatomic, readwrite) NSInteger lastHealth;
@property (nonatomic, assign) CCLabelTTF *healthLabelShadow;
@property (nonatomic, assign) CCLabelTTF *bossNameShadow;
@end

@implementation BossHealthView

@synthesize bossNameLabel, healthLabel, bossData, lastHealth, bossHealthBack;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;

        CCSprite *portraitSprite = [CCSprite spriteWithSpriteFrameName:@"boss_portrait_back.png"];
        [portraitSprite setAnchorPoint:CGPointZero];
        [portraitSprite setPosition:CGPointMake(660, -60)];
        [self addChild:portraitSprite z:10];
        
        CCSprite *portrait = [CCSprite spriteWithSpriteFrameName:@"boss_default.png"];
        [portrait setPosition:CGPointMake(84,84)];
        [portraitSprite addChild:portrait];
        
        
        lastHealth = 0;
        
        CCSprite *boss_plate_sprite = [CCSprite spriteWithSpriteFrameName:@"boss_plate.png"];
        [boss_plate_sprite setAnchorPoint:CGPointZero];
        [self addChild:boss_plate_sprite];
        
        CCSprite *healthBar = [CCSprite spriteWithSpriteFrameName:@"boss_health_back.png"];
        
        self.bossHealthBack = [ClippingNode node];
        [self.bossHealthBack setAnchorPoint:CGPointZero];
        [self.bossHealthBack setContentSize:healthBar.contentSize];
        [self.bossHealthBack setClippingRegion:CGRectMake(HEALTH_INSET_WIDTH,HEALTH_INSET_HEIGHT, healthBar.contentSize.width, healthBar.contentSize.height)];
        [healthBar setAnchorPoint:ccp(0,0)];
        [healthBar setPosition:CGPointMake(HEALTH_INSET_WIDTH, HEALTH_INSET_HEIGHT)];
        [self.bossHealthBack addChild:healthBar z:1];
    
        
        self.bossNameLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(280, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold" fontSize:32.0];
        self.bossNameLabel.position = CGPointMake(510, 14);
        [self.bossNameLabel setColor:ccc3(220, 220, 220)];
        
        self.bossNameShadow = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(280, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold" fontSize:32.0];
        self.bossNameShadow.position = CGPointMake(509, 13);
        [self.bossNameShadow setColor:ccc3(25, 25, 25)];

        
        self.healthLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold"  fontSize:32.0];
        [self.healthLabel setColor:ccc3(230, 230, 230)];
        [self.healthLabel setPosition:CGPointMake(300, 60)];
        
        self.healthLabelShadow = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(200, 40) hAlignment:kCCTextAlignmentRight fontName:@"Marion-Bold"  fontSize:32.0];
        [self.healthLabelShadow setColor:ccc3(25, 25, 25)];
        [self.healthLabelShadow setOpacity:155];
        [self.healthLabelShadow setPosition:CGPointMake(299, 59)];
        
        [self addChild:self.bossNameShadow z:9];
        [self addChild:self.bossHealthBack];
        [self addChild:self.bossNameLabel z:10];
        [self addChild:self.healthLabel z:10];
        [self addChild:self.healthLabelShadow z:self.healthLabel.zOrder - 1];
    }
    return self;
}



-(void)setBossData:(Boss*)theBoss
{
	bossData = theBoss;
	
	[self.bossNameLabel setString:[bossData namePlateTitle]];
    [self.bossNameShadow setString:[bossData namePlateTitle]];
	lastHealth = theBoss.health;
    
    [self.abilityDescriptionsView removeFromParentAndCleanup:YES];
    self.abilityDescriptionsView = [[[BossAbilityDescriptionsView alloc] initWithBoss:self.bossData] autorelease];
    [self.abilityDescriptionsView setAnchorPoint:CGPointZero];
    [self.abilityDescriptionsView setPosition:CGPointMake(-454, -360)];
    [self.abilityDescriptionsView setDelegate:self];
    [self addChild:self.abilityDescriptionsView];
	
}

-(void)updateHealth
{
    if (bossData && bossData.health < lastHealth){
        int startingFuzzX = arc4random() % 20 + self.bossHealthBack.clippingRegion.origin.x + self.bossHealthBack.clippingRegion.size.width ;
        int startingFuzzY = arc4random() % 20;
        int heal = bossData.health - lastHealth;
        CCLabelTTF *shadowLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [shadowLabel setColor:ccBLACK];
        [shadowLabel setPosition:CGPointMake(startingFuzzX -1, self.contentSize.height + 1 + startingFuzzY)];
        
        CCLabelTTF *sctLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [sctLabel setColor:ccWHITE];
        [sctLabel setPosition:CGPointMake(startingFuzzX, self.contentSize.height + startingFuzzY)];
        
        [self addChild:shadowLabel z:10];
        [self addChild:sctLabel z:11];
        
        int direction = arc4random() % 2 == 1 ? -1 : 1;
        int distanceFuzz = arc4random() % 50;
        [sctLabel runAction:[CCSequence actions:[CCSpawn actions:[CCJumpBy actionWithDuration:2.0 position:CGPointMake(direction * 50 + distanceFuzz, -50) height:20 jumps:1], [CCFadeOut actionWithDuration:2.0], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];}], nil]];
        [shadowLabel runAction:[CCSequence actions:[CCSpawn actions:[CCJumpBy actionWithDuration:2.0 position:CGPointMake(direction * 50 + distanceFuzz, -50) height:20 jumps:1], [CCFadeOut actionWithDuration:2.0], nil], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [node removeFromParentAndCleanup:YES];}], nil]];
    }
    
    lastHealth = bossData.health;
	NSString *healthText;
	if (bossData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f%%", (((float)bossData.health) / bossData.maximumHealth)*100];
	}
	else {
		healthText = @"Dead";
	}
	
	if (![healthText isEqualToString:[self.healthLabel string]]){
		[self.healthLabel setString:healthText];
        [self.healthLabelShadow setString:healthText];
	}
    
    double percentageOfHealth = ((float)[self.bossData health])/[self.bossData maximumHealth];
    [self.bossHealthBack setClippingRegion:CGRectMake(HEALTH_INSET_WIDTH-(self.bossHealthBack.clippingRegion.size.width * (1 - percentageOfHealth)), self.bossHealthBack.clippingRegion.origin.y, self.bossHealthBack.clippingRegion.size.width, self.bossHealthBack.clippingRegion.size.height)];
    
    [self.abilityDescriptionsView update];
}

- (void)abilityDescriptionViewDidSelectAbility:(AbilityDescriptor *)descriptor {
    [self.delegate bossHealthViewShouldDisplayAbility:descriptor];
}


- (void)dealloc {
    [bossNameLabel release];
    [healthLabel release];
    [super dealloc];
}


@end
