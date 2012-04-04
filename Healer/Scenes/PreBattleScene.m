//
//  PreBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "PreBattleScene.h"
#import "Player.h"
#import "Boss.h"
#import "Raid.h"
#import "Spell.h"
#import "GamePlayScene.h"
#import "RaidMemberPreBattleCard.h"
#import "QuickPlayScene.h"

@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) Raid *raid;

-(void)back;
-(void)doneButton;
@end

@implementation PreBattleScene
@synthesize raid = _raid, boss = _boss, player = _player, maxPlayers, levelNumber;

-(id)initWithRaid:(Raid*)raid boss:(Boss*)boss andPlayer:(Player*)player{
    if (self = [super init]){
        self.raid = raid;
        self.player = player;
        self.boss = boss;
        
        self.maxPlayers = raid.raidMembers.count; //Assume the number of players in the raid passed in is our max
        
        CCMenu *doneButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Battle!" fontName:@"Arial" fontSize:32] target:self selector:@selector(doneButton)], nil];
        [doneButton setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .8, [CCDirector sharedDirector].winSize.height * .05 )];
        
        [self addChild:doneButton];
        
        CCLayerColor *spellsGroupingBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
        [spellsGroupingBackground setPosition:ccp([CCDirector sharedDirector].winSize.width * .7, [CCDirector sharedDirector].winSize.height * .25)];
        [spellsGroupingBackground setContentSize:CGSizeMake(298,500)];
        [self addChild:spellsGroupingBackground];
        
        
        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Spells:" fontName:@"Arial" fontSize:32];
        [activeSpellsLabel  setColor:ccBLACK];
        [activeSpellsLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .75, [CCDirector sharedDirector].winSize.height * .85)];
        [self addChild:activeSpellsLabel];
        
        int i = 0;
        for (Spell *activeSpell in self.player.activeSpells){
            CCLayerColor *spellIcon = [CCLayerColor layerWithColor:ccc4(255, 0, 0, 255)];
            [spellIcon setContentSize:CGSizeMake(100, 100)];
            [spellIcon setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .7, 530 - (105 * i))];
            
            CCLabelTTF *spellNamePH = [CCLabelTTF labelWithString:activeSpell.title fontName:@"Arial" fontSize:20];
            [spellNamePH setPosition:ccp(50,50)];
            [spellIcon addChild:spellNamePH];
            
            CCLayerColor *spellDetailsBackground = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255)];
            [spellDetailsBackground setContentSize:CGSizeMake(200, 100)];
            [spellDetailsBackground setPosition:CGPointMake(814, 530 - (105 * i))];
            [self addChild:spellIcon];
            [self addChild:spellDetailsBackground];
            
            CCLabelTTF *spellDetailsLabel = [CCLabelTTF labelWithString:activeSpell.description dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
            [spellDetailsLabel setColor:ccBLACK];
            [spellDetailsLabel setPosition:ccp(102,14)];
            
            CCLabelTTF *spellCostLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cost: %i", activeSpell.energyCost] dimensions:CGSizeMake(200, 20) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
            [spellCostLabel setColor:ccBLACK];
            [spellCostLabel setPosition:ccp(102, 86)];
            
            CCLabelTTF *spellCastTimeLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cast Time: %1.2f", activeSpell.castTime] dimensions:CGSizeMake(200, 20) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
            [spellCastTimeLabel setColor:ccBLACK];
            [spellCastTimeLabel setPosition:ccp(102, 70)];
            
            CCLabelTTF *spellCooldownLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Cooldown: %1.2f", activeSpell.cooldown] dimensions:CGSizeMake(200, 40) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:14];
            [spellCooldownLabel setColor:ccBLACK];
            [spellCooldownLabel setPosition:ccp(102, 44)];
            
            
            [spellDetailsBackground addChild:   spellDetailsLabel];
            [spellDetailsBackground addChild:   spellCostLabel];
            [spellDetailsBackground addChild:   spellCastTimeLabel];
            [spellDetailsBackground addChild:   spellCooldownLabel];
            
            i++;
        }
        
        

        CCLabelTTF *alliesLabel = [CCLabelTTF labelWithString:@"Your Allies:" fontName:@"Arial" fontSize:32];
        [alliesLabel setPosition:ccp(120, 680)];
        [self addChild:alliesLabel];
        
        NSMutableDictionary *raidMemberTypes = [NSMutableDictionary dictionaryWithCapacity:5];
        
        for (RaidMember* member in self.raid.raidMembers){
            NSNumber *number = [raidMemberTypes objectForKey:member.title];
            if (!number){
                number = [NSNumber numberWithInt:1];
                [raidMemberTypes setObject:number forKey:member.title];
            }else{
                number = [NSNumber numberWithInt:[number intValue] + 1];
            }
            [raidMemberTypes setObject:number forKey:member.title];
        }
        
        i = 0;
        for (NSString *types in raidMemberTypes){
            RaidMember *member = nil;
            for (RaidMember *thisMember in self.raid.raidMembers){
                if ([thisMember.title isEqualToString:types]){
                    member = thisMember; 
                    break;
                }
            }
            RaidMemberPreBattleCard *preBattleCard = [[RaidMemberPreBattleCard alloc] initWithFrame:CGRectMake(50, 540 - (101 * i), 200, 100) count:[[raidMemberTypes objectForKey:types] intValue] andRaidMember:member];
            [self addChild:preBattleCard];
            [preBattleCard release];
            i++;
        }
        
        CCLabelTTF *back = [CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:32.0];
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:back target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(50, [CCDirector sharedDirector].winSize.height * .95)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
        
        if (boss.info){
            CCLabelTTF *yourEnemyLAbel = [CCLabelTTF labelWithString:@"Your Enemy:" fontName:@"Arial" fontSize:32.0];
            CCLabelTTF *bossNameLabel = [CCLabelTTF labelWithString:self.boss.title fontName:@"Arial" fontSize:32.0];
            [yourEnemyLAbel setPosition:CGPointMake(520, 600)];
            [bossNameLabel setPosition:CGPointMake(520, 550)];
            CCLabelTTF *bossLabel = [CCLabelTTF labelWithString:self.boss.info dimensions:CGSizeMake(300, 500) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16.0 ];
            
            [bossLabel setPosition:CGPointMake(525, 250)];
            [self addChild:bossLabel];
            [self addChild:yourEnemyLAbel];
            [self addChild:bossNameLabel];
        }
        
    }
    return self;
}

-(void)back{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:1.0 scene:[[[QuickPlayScene alloc] init] autorelease]]];
}
-(void)doneButton{
    GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:self.raid boss:self.boss andPlayer:self.player];
    [gps setLevelNumber:self.levelNumber];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
    [gps release];

}
@end
