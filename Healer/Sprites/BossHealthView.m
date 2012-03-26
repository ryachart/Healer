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
        self.bossNameLabel.position = CGPointMake(100, 50);
        self.bossNameLabel.contentSize = frame.size;
        [self.bossNameLabel setColor:ccRED];
        
        self.healthLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32.0];
        [self.healthLabel setColor:ccRED];
        self.healthLabel.position = CGPointMake(frame.size.width * .35, frame.size.height * .3);
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
        int heal = bossData.health - lastHealth;
        CCLabelTTF *shadowLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [shadowLabel setColor:ccBLACK];
        [shadowLabel setPosition:CGPointMake(self.contentSize.width /2 -1 , self.contentSize.height /2 + 1)];
        
        CCLabelTTF *sctLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", heal] fontName:@"Arial" fontSize:20];
        [sctLabel setColor:ccRED];
        [sctLabel setPosition:CGPointMake(self.contentSize.width /2 , self.contentSize.height /2)];
        
        [self addChild:shadowLabel z:10];
        [self addChild:sctLabel z:11];
        
        int direction = arc4random() % 2 == 1 ? -1 : 1;
        [sctLabel runAction:[CCSpawn actions:[CCJumpBy actionWithDuration:2.0 position:CGPointMake(direction * 50, -50) height:20 jumps:1], [CCFadeOut actionWithDuration:2.0], nil]];
        [shadowLabel runAction:[CCSpawn actions:[CCJumpBy actionWithDuration:2.0 position:CGPointMake(direction * 50, -50) height:20 jumps:1], [CCFadeOut actionWithDuration:2.0], nil]];
    }
    
    lastHealth = bossData.health;
	NSString *healthText;
	if (bossData.health >= 1){
		healthText = [NSString stringWithFormat:@"%3.1f", (((float)bossData.health) / bossData.maximumHealth)*100];
	}
	else {
		healthText = @"Dead";
	}
	
	if (![healthText isEqualToString:[self.healthLabel string]]){
		//NSLog(@"DIFFERENT");
		[self. healthLabel setString:healthText];
		//[self setNeedsDisplay];
	}
    
    double percentageOfHealth = ((float)[self.bossData health])/[self.bossData maximumHealth];
    CGFloat width = self.contentSize.width * .990 * percentageOfHealth;
    [self.healthFrame setContentSize:CGSizeMake(width, self.healthFrame.contentSize.height)];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//	CGFloat x = CGRectGetWidth(self.frame) * .005;
//	CGFloat y = CGRectGetHeight(self.frame) * .05;
//	CGFloat height = CGRectGetHeight(self.frame) * .90;
//	double percentageOfHealth = ((float)[bossData health])/[bossData maximumHealth];
//	CGFloat width = CGRectGetWidth(self.frame) * .990 * percentageOfHealth;
//	//NSLog(@"Width: %f", width);
//	
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextSetRGBFillColor(context,1,0, 0, 1);
//	
//	UIRectFill(CGRectMake(x,y,width,height));
//}


- (void)dealloc {
    [super dealloc];
}


@end
