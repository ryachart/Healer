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
    if (self = [super init]){
        self.color = ccBLACK;
        self.opacity = 100;
        
        self.informationLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(500, 300) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.informationLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .65)];
        [self.informationLabel setColor:ccYELLOW];
        
        self.highlightLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 255, 80)];
        [self.highlightLayer setVisible:NO];
        
        [self addChild:self.highlightLayer z:85];
        [self addChild:self.informationLabel z: 100];
        
    }
    return self;
}


-(void)showWelcome{
    [self.informationLabel setString:@"Welcome to Healer.  I'll show you how to play"];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime actionWithDuration:3.0], [CCFadeOut actionWithDuration:1.0], nil]];
    
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:4.0], [CCCallFuncN actionWithTarget:self selector:@selector(showPlayerInformation)], nil]];
    
}

-(void)showPlayerInformation{
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.informationLabel setString:@"Here you'll find information about your health and energy.  Energy is used to cast spells."];
    
    self.highlightLayer.position = CGPointMake(800, 500);
    self.highlightLayer.contentSize = CGSizeMake(200, 200);
    [self.highlightLayer runAction:[CCSequence actions:[CCFadeIn actionWithDuration:1.5], [CCDelayTime actionWithDuration:3.0], [CCFadeOut actionWithDuration:1.5], nil]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showSpellInformation)], nil]];
}

-(void)showSpellInformation {
        [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showBossInformation)], nil]];
}

-(void)showBossInformation{
        [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showRaidInformation)], nil]];
}

-(void)showRaidInformation{
        [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showGoodLuck)], nil]];
}

-(void)showGoodLuck{
        [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:delegate selector:@selector(ftueLayerDidComplete)], nil]];
}
@end
