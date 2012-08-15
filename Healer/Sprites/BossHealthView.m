//
//  BossHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BossHealthView.h"
#import "ClippingNode.h"

@interface BossHealthView ()
@property (nonatomic, assign) CCSprite *bossHealthFrame;
@property (nonatomic, assign) ClippingNode *bossHealthBack;
@property (nonatomic, readwrite) NSInteger lastHealth;
@end

@implementation BossHealthView

@synthesize bossNameLabel, healthLabel, bossData, lastHealth, bossHealthBack, bossHealthFrame;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;

        CCSprite *portraitSprite = [CCSprite spriteWithSpriteFrameName:@"boss_portrait_back.png"];
        [portraitSprite setAnchorPoint:CGPointZero];
        [self addChild:portraitSprite z:10];
        
        CCSprite *portrait = [CCSprite spriteWithSpriteFrameName:@"boss_default.png"];
        [portrait setAnchorPoint:CGPointZero];
        [portraitSprite addChild:portrait];
        
        
        lastHealth = 0;
        CGPoint healthBarFramePosition = CGPointMake(0, 0);
        
        CCSprite *boss_plate_sprite = [CCSprite spriteWithSpriteFrameName:@"boss_plate.png"];
        [boss_plate_sprite setAnchorPoint:CGPointZero];
        [self addChild:boss_plate_sprite];
        
        CCSprite *healthBar = [CCSprite spriteWithSpriteFrameName:@"boss_health_back.png"];
        
        self.bossHealthBack = [ClippingNode node];
        [self.bossHealthBack setContentSize:healthBar.contentSize];
        [self.bossHealthBack setClippingRegion:CGRectMake(0,0, healthBar.contentSize.width, healthBar.contentSize.height)];
        [healthBar setAnchorPoint:ccp(0,0)];
        [healthBar setPosition:CGPointMake(20, 0)];
        [self.bossHealthBack addChild:healthBar z:1];
        
        self.bossHealthFrame = [CCSprite spriteWithSpriteFrameName:@"boss_health_frame.png"];
        self.bossHealthFrame.anchorPoint = CGPointZero;
        self.bossHealthFrame.position = healthBarFramePosition;
        
        self.bossNameLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32.0];
        self.bossNameLabel.position = CGPointMake(300, 160);
        self.bossNameLabel.contentSize = frame.size;
        [self.bossNameLabel setColor:ccBLACK];
        
        self.healthLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32.0];
        [self.healthLabel setColor:ccBLACK];
        self.healthLabel.contentSize = CGSizeMake(frame.size.width * .5, frame.size.height * .25);
        [self.healthLabel setPosition:CGPointMake(300, 120)];
        
        [self addChild:self.bossHealthBack];
        [self addChild:self.bossHealthFrame];
        [self addChild:self.bossNameLabel z:10];
        [self addChild:self.healthLabel z:10];
    }
    return self;
}



-(void)setBossData:(Boss*)theBoss
{
	bossData = theBoss;
	
	[self.bossNameLabel setString:[bossData title]];
	lastHealth = theBoss.health;
    
    [self.abilityDescriptionsView removeFromParentAndCleanup:YES];
    self.abilityDescriptionsView = [[[BossAbilityDescriptionsView alloc] initWithBoss:self.bossData] autorelease];
    [self.abilityDescriptionsView setAnchorPoint:CGPointZero];
    [self.abilityDescriptionsView setPosition:CGPointMake(-470, -320)];
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
		[self. healthLabel setString:healthText];
	}
    
    double percentageOfHealth = ((float)[self.bossData health])/[self.bossData maximumHealth];
    [self.bossHealthBack setClippingRegion:CGRectMake(0-(self.bossHealthBack.clippingRegion.size.width * (1 - percentageOfHealth)), self.bossHealthBack.clippingRegion.origin.y, self.bossHealthBack.clippingRegion.size.width, self.bossHealthBack.clippingRegion.size.height)];
    
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
