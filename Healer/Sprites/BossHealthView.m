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
        
        lastHealth = 0;
        CGPoint midPoint = CGPointMake(frame.size.width * .5, frame.size.height * .5);
        CGPoint healthBarFramePosition = CGPointMake(-50, -50);
        
        CCSprite *healthBar = [CCSprite spriteWithSpriteFrameName:@"boss_health_back.png"];
        
        self.bossHealthBack = [ClippingNode node];
        [self.bossHealthBack setContentSize:healthBar.contentSize];
        [self.bossHealthBack setClippingRegion:CGRectMake(0,0, healthBar.contentSize.width -50, healthBar.contentSize.height - 50)];
        [healthBar setAnchorPoint:ccp(0,0)];
        [healthBar setPosition:healthBarFramePosition];
        [self.bossHealthBack addChild:healthBar z:1];
        
        self.bossHealthFrame = [CCSprite spriteWithSpriteFrameName:@"boss_health_frame.png"];
        self.bossHealthFrame.anchorPoint = CGPointZero;
        self.bossHealthFrame.position = healthBarFramePosition;
        
        self.bossNameLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32.0];
        self.bossNameLabel.position = CGPointMake(300, 70);
        self.bossNameLabel.contentSize = frame.size;
        [self.bossNameLabel setColor:ccWHITE];
        
        self.healthLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32.0];
        [self.healthLabel setColor:ccWHITE];
        self.healthLabel.position = midPoint;
        self.healthLabel.contentSize = CGSizeMake(frame.size.width * .5, frame.size.height * .25);

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
	
}

-(void)updateHealth
{
    if (bossData && bossData.health < lastHealth){
        int startingFuzzX = arc4random() % 20 + self.bossHealthBack.clippingRegion.origin.x + self.bossHealthBack.clippingRegion.size.width ;
        int startingFuzzY = arc4random() % 20;
        int heal = bossData.health - lastHealth;
        CCLabelTTF *shadowLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [shadowLabel setColor:ccBLACK];
        [shadowLabel setPosition:CGPointMake(startingFuzzX -1, self.contentSize.height /2 + 1 + startingFuzzY)];
        
        CCLabelTTF *sctLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [sctLabel setColor:ccWHITE];
        [sctLabel setPosition:CGPointMake(startingFuzzX, self.contentSize.height /2 + startingFuzzY)];
        
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
		healthText = [NSString stringWithFormat:@"%3.1f%", (((float)bossData.health) / bossData.maximumHealth)*100];
	}
	else {
		healthText = @"Dead";
	}
	
	if (![healthText isEqualToString:[self.healthLabel string]]){
		[self. healthLabel setString:healthText];
	}
    
    double percentageOfHealth = ((float)[self.bossData health])/[self.bossData maximumHealth];
    [self.bossHealthBack setClippingRegion:CGRectMake(0-(self.bossHealthBack.clippingRegion.size.width * (1 - percentageOfHealth)), self.bossHealthBack.clippingRegion.origin.y, self.bossHealthBack.clippingRegion.size.width, self.bossHealthBack.clippingRegion.size.height)];
}


- (void)dealloc {
    [super dealloc];
}


@end
