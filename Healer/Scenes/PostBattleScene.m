//
//  PostBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/3/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "PostBattleScene.h"
#import "QuickPlayScene.h"
#import "CombatEvent.h"
#import "Boss.h"

@interface PostBattleScene()
-(void)done;
@end

@implementation PostBattleScene


-(id)initWithVictory:(BOOL)victory andEventLog:(NSArray *)eventLog{
    self = [super init];
    if (self){
        if (victory){
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"VICTORY!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }else{
            CCLabelTTF *victoryLabel = [CCLabelTTF labelWithString:@"DEFEAT!" fontName:@"Arial" fontSize:72];
            [victoryLabel setPosition:CGPointMake(512, 384)];
            [self addChild:victoryLabel];
        }
    
        CCMenuItemLabel *done = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Continue" fontName:@"Arial" fontSize:32] target:self selector:@selector(done)];
        
        CCMenu *menu = [CCMenu menuWithItems:done, nil];
        menu.position = CGPointMake(512, 200);
        [self addChild:menu];
        
        int totalHealingDone = 0;
        
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeHeal){
                totalHealingDone += [[event value] intValue];
            }
        }
        
        int raidersLost = 0;
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeMemberDied){
                raidersLost ++;            }
        }
        
        int totalDamageTaken = 0;
        for (CombatEvent *event in eventLog){
            if (event.type == CombatEventTypeDamage && [[event source] isKindOfClass:[Boss class]]){
                NSInteger dmgVal = [[event value] intValue];
                if (dmgVal < 0) dmgVal *= -1;
                totalDamageTaken += dmgVal;            
            }
        }
        
        CCLabelTTF *healingDoneLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Healing Done: %i", totalHealingDone] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [healingDoneLabel setPosition:CGPointMake(200, 200)];
        
        CCLabelTTF *damageTakenLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Damage Taken: %i", totalDamageTaken] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [damageTakenLabel setPosition:CGPointMake(200, 135)];
        
        CCLabelTTF *playersLostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Allies Lost:  %i", raidersLost] dimensions:CGSizeMake(350, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24.0];
        [playersLostLabel setPosition:CGPointMake(200, 90)];
        
        [self addChild:healingDoneLabel];
        [self addChild:damageTakenLabel];
        [self addChild:playersLostLabel];
        
    }
    return self;
}
                            
-(void)done{
    QuickPlayScene *qps = [[QuickPlayScene alloc] init];
    [[CCDirector sharedDirector] replaceScene:qps];
    [qps release];
}
@end
