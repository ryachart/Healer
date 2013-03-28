//
//  GamePlayFTUELayer.m
//  Healer
//
//  Created by Ryan Hart on 3/28/12.
//

#import "GamePlayFTUELayer.h"
#import "CCLabelTTFShadow.h"

@interface GamePlayFTUELayer ()
@property (nonatomic, assign) CCSprite *ftueArrow;
@property (nonatomic, assign) CCLabelTTFShadow *informationLabel;
@end

@implementation GamePlayFTUELayer
-(id)init{
    if (self = [super initWithColor:ccc4(0, 0, 0, 100)]){
        self.ftueArrow = [CCSprite spriteWithSpriteFrameName:@"ftue_arrow.png"];
        [self.ftueArrow setVisible:NO];
        [self addChild:self.ftueArrow];
        
        self.informationLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(500, 300) hAlignment:UITextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.informationLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .5, [CCDirector sharedDirector].winSize.height * .62)];
        [self.informationLabel setColor:ccYELLOW];
        [self addChild:self.informationLabel z: 100];
        
    }
    return self;
}

-(void)complete{
    [self.delegate ftueLayerDidComplete:self];
}


-(void)showWelcome{
    [self.informationLabel setString:@"Welcome, Healer.  You are a powerful spellcaster that can restore health to allies when they are injured by enemies."];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime actionWithDuration:5.0], [CCFadeOut actionWithDuration:1.0], nil]];
    
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:6.0], [CCCallFuncN actionWithTarget:self selector:@selector(showRaidInformation)], nil]];
    
}

-(void)showRaidInformation{
    [self.informationLabel setString:@"These bars represent the health of your allies.\nTap these to select targets for your spells."];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.ftueArrow setPosition:CGPointMake(210, 320)];
    [self.ftueArrow setVisible:YES];
    
    self.ftueArrow.rotation = 0.0;
    [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(0, -40)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(0, 40)], nil]]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showSpellInformation)], nil]];
}

-(void)showSpellInformation {
    [self.informationLabel setString:@"Tap these spell buttons to heal allies!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.ftueArrow setPosition:CGPointMake(820, 415)];
    self.ftueArrow.rotation = 270.0f;
    [self.ftueArrow stopAllActions];
    [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(-40, 0)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(40, 0)], nil]]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showPlayerInformation)], nil]];
}

-(void)showPlayerInformation{
    [self.informationLabel setString:@"Casting spells spends your Mana."];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];

    self.ftueArrow.position = CGPointMake(720, 500);
    self.ftueArrow.rotation = 270.0f;
    [self.ftueArrow stopAllActions];
    [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(-40, 0)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(40, 0)], nil]]];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showBossInformation)], nil]];
}

-(void)showBossInformation{
    self.informationLabel.position = ccpAdd(self.informationLabel.position, ccp(0, -160));
    [self.informationLabel setString:@"This is the health of your enemy.\nWhen your enemy is vanquished you win!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.ftueArrow setPosition:CGPointMake(512, 610)];
    self.ftueArrow.rotation = 180.0f;
    [self.ftueArrow stopAllActions];
    [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(0, -40)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(0, 40)], nil]]];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showBossAbilityInformation)], nil]];
}

- (void)showBossAbilityInformation {
    [self.informationLabel setString:@"These represent the abilities of your enemies.\nTap on them to learn what your enemy can do."];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.ftueArrow setPosition:CGPointMake(236, 590)];
    self.ftueArrow.rotation = 180.0f;
    [self.ftueArrow stopAllActions];
    [self.ftueArrow runAction:[CCRepeatForever actionWithAction:[CCSequence actions:[CCEaseBackOut actionWithAction:[CCMoveBy actionWithDuration:.5 position:CGPointMake(0, -40)]],[CCMoveBy actionWithDuration:.33 position:CGPointMake(0, 40)], nil]]];
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(showGoodLuck)], nil]];
}


-(void)showGoodLuck{
    [self.informationLabel setString:@"Good luck!"];
    [self.informationLabel runAction:[CCFadeIn actionWithDuration:1.0]];
    [self.ftueArrow setVisible:NO];
    
    [self.informationLabel runAction:[CCSequence actions:[CCDelayTime  actionWithDuration:4.5], [CCFadeOut actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(complete)], nil]];
}
@end
