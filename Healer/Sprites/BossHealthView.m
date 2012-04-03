//
//  BossHealthView.m
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BossHealthView.h"

@interface BossHealthView ()
@property (nonatomic, readwrite) NSInteger lastHealth;
@end

@implementation BossHealthView

@synthesize bossNameLabel, healthLabel, bossData, healthFrame, lastHealth;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        // Initialization code
        self.position = frame.origin;
        self.contentSize = frame.size;
        [self setOpacity:255];
        
        lastHealth = 0;
        
        self.healthFrame = [[[CCLayerColor alloc] initWithColor:ccc4(0, 255, 0, 255)] autorelease];
        [self.healthFrame setPosition:CGPointMake(0, 0)];
        [self.healthFrame setContentSize:frame.size];
        
        self.bossNameLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32.0];
        self.bossNameLabel.position = CGPointMake(200, 50);
        self.bossNameLabel.contentSize = frame.size;
        [self.bossNameLabel setColor:ccRED];
        
        self.healthLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32.0];
        [self.healthLabel setColor:ccRED];
        self.healthLabel.position = CGPointMake(frame.size.width * .5, frame.size.height * .5);
        self.healthLabel.contentSize = CGSizeMake(frame.size.width * .5, frame.size.height * .25);

        [self addChild:self.healthFrame];
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
        int startingFuzzX = arc4random() % 10;
        int startingFuzzY = arc4random() % 10;
        int heal = bossData.health - lastHealth;
        CCLabelTTF *shadowLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [shadowLabel setColor:ccBLACK];
        [shadowLabel setPosition:CGPointMake(self.contentSize.width /2 -1 + startingFuzzX , self.contentSize.height /2 + 1 + startingFuzzY)];
        
        CCLabelTTF *sctLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [sctLabel setColor:ccRED];
        [sctLabel setPosition:CGPointMake(self.contentSize.width /2 + startingFuzzX, self.contentSize.height /2 + startingFuzzY)];
        
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
    CGFloat width = self.contentSize.width * .990 * percentageOfHealth;
    [self.healthFrame setContentSize:CGSizeMake(width, self.healthFrame.contentSize.height)];
}


- (void)dealloc {
    [super dealloc];
}


@end
