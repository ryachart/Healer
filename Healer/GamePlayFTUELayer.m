//
//  GamePlayFTUELayer.m
//  Healer
//
//  Created by Ryan Hart on 3/28/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "GamePlayFTUELayer.h"

@implementation GamePlayFTUELayer
@synthesize highlightLayer, informationLabel, delegate;
-(id)init{
    if (self = [super initWithColor:ccc4(0, 0, 0, 100)]){
        
        self.informationLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.informationLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .65)];
        [self.informationLabel setColor:ccYELLOW];
        
        self.highlightLayer = [CCLayerColor layerWithColor:ccc4(0, 255, 255, 0)];
        
        [self addChild:self.highlightLayer z:85];
        [self addChild:self.informationLabel z: 100];
        
    }
    return self;
}

-(void)complete{
    [self.delegate ftueLayerDidComplete:self];
}


-(void)showWelcome{
    [self.informationLabel setString:@"Welcome to Healer.  I'll show you how to play"];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime actionWithDuration:3.0], [CCFadeOut actionWithDuration:1.0], nil]];
    
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:4.0], [CCCallFuncN actionWithTarget:self selector:@selector(showPlayerInformation)], nil]];
    
}

-(void)showPlayerInformation{
    [self.informationLabel setString:@"Here you'll find information about your health and energy.  Energy is used to cast spells."];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.highlightLayer setContentSize:CGSizeMake(210, 110)];
    [self.highlightLayer setPosition:CGPointMake(900, 600)];
    
    self.highlightLayer.position = CGPointMake(800, 500);
    self.highlightLayer.contentSize = CGSizeMake(200, 200);
    [self.highlightLayer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:80], [CCDelayTime actionWithDuration:3.0], [CCFadeTo actionWithDuration:1.5 opacity:0], nil]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showSpellInformation)], nil]];
}

-(void)showSpellInformation {
    [self.informationLabel setString:@"These are your spells.  Tap these to heal selected allies!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.highlightLayer setContentSize:CGSizeMake(200, 500)];
    [self.highlightLayer setPosition:CGPointMake(800, 10)];
    [self.highlightLayer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:80], [CCDelayTime actionWithDuration:3.0], [CCFadeTo actionWithDuration:1.5 opacity:0], nil]];

    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showRaidInformation)], nil]];
}

-(void)showRaidInformation{ 
    [self.informationLabel setString:@"These are your allies.  Tap on these to select targets for your spells."];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.highlightLayer setContentSize:CGSizeMake(520, 520)];
    [self.highlightLayer setPosition:CGPointMake(5, 95)];
    [self.highlightLayer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:80], [CCDelayTime actionWithDuration:3.0], [CCFadeTo actionWithDuration:1.5 opacity:0], nil]];    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showBossInformation)], nil]];
}

-(void)showBossInformation{
    [self.informationLabel setString:@"This is the health of your enemy.  When your enemy is vanquished you win!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.highlightLayer setContentSize:CGSizeMake(1000, 110)];
    [self.highlightLayer setPosition:CGPointMake(20, 640)];
    [self.highlightLayer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:80], [CCDelayTime actionWithDuration:3.0], [CCFadeTo actionWithDuration:1.5 opacity:0], nil]];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showGoodLuck)], nil]];
}


-(void)showGoodLuck{
    [self.informationLabel setString:@"Good luck!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(complete)], nil]];
}
@end
