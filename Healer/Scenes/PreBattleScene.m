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


@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) Raid *raid;

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
        
        int trollCount = 0;
        int witchCount = 0;
        int ogreCount = 0;
        for (RaidMember *member in self.raid.raidMembers){
            if ([member.sourceName isEqualToString:@"Witch"]){
                witchCount++;
            }
            if ([member.sourceName isEqualToString:@"Ogre"]){
                ogreCount++;
            }
            if ([member.sourceName isEqualToString:@"Troll"]){
                trollCount++;
            }
        }
        

        CCLabelTTF *alliesLabel = [CCLabelTTF labelWithString:@"Your Allies:" fontName:@"Arial" fontSize:32];
        [alliesLabel setPosition:ccp(100, 600)];
        [self addChild:alliesLabel];
        int allySlotsUsed = 0;
        if (ogreCount >0){
            CCLayerColor *ogreBackground = [CCLayerColor layerWithColor:ccc4(255, 0, 0, 255)];
            [ogreBackground setPosition:ccp(70, 450)];
            [ogreBackground setContentSize:CGSizeMake(100, 100)];
            [self addChild:ogreBackground];
            
            CCLayerColor *ogreDetailBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
            [ogreDetailBackground setPosition: ccp(170, 450)];
            [ogreDetailBackground setContentSize:CGSizeMake(200, 100)];
            [self addChild:ogreDetailBackground];
            
            CCLabelTTF *ogreHealthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %i", [Ogre defaultOgre].maximumHealth] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [ogreHealthLabel setColor:ccBLACK];
            [ogreHealthLabel setPosition:ccp(100, 78)];
            [ogreDetailBackground addChild:ogreHealthLabel];
            
            CCLabelTTF *ogreDPSLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"DPS: %1.2f", [Ogre defaultOgre].dps] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [ogreDPSLabel setColor:ccBLACK];
            [ogreDPSLabel setPosition:ccp(100, 58)];
            [ogreDetailBackground addChild:ogreDPSLabel];
            
            CCLabelTTF *ogresLabel = [CCLabelTTF labelWithString:@"Ogres" dimensions:CGSizeMake(100, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32];
            [ogresLabel setPosition:ccp(50, 78)];
            [ogreBackground addChild:ogresLabel];
            
            CCLabelTTF *ogreCountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", ogreCount] dimensions:CGSizeMake(50, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32];
            [ogreCountLabel setPosition:ccp(50, 38)];
            [ogreBackground addChild:ogreCountLabel];
            allySlotsUsed++;
        }
        if (trollCount > 0){
            CCLayerColor *trollBackground = [CCLayerColor layerWithColor:ccc4(0, 255, 0, 255)];
            [trollBackground setPosition:CGPointMake(70, 345 + ((1 - allySlotsUsed) * 105))];
            [trollBackground setContentSize:CGSizeMake(100, 100)];
            [self addChild:trollBackground];
            
            CCLayerColor *trollDetailBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
            [trollDetailBackground setPosition: ccp(170, 345 + ((1 - allySlotsUsed) * 105))];
            [trollDetailBackground setContentSize:CGSizeMake(200, 100)];
            [self addChild:trollDetailBackground];
            
            CCLabelTTF *trollHealthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %i", [Troll defaultTroll].maximumHealth] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [trollHealthLabel setColor:ccBLACK];
            [trollHealthLabel setPosition:ccp(100, 78)];
            [trollDetailBackground addChild:trollHealthLabel];
            
            CCLabelTTF *trollDPSLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"DPS: %1.2f", [Troll defaultTroll].dps] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [trollDPSLabel setColor:ccBLACK];
            [trollDPSLabel setPosition:ccp(100, 58)];
            [trollDetailBackground addChild:trollDPSLabel];
            
            CCLabelTTF *trollsLabel = [CCLabelTTF labelWithString:@"Trolls" dimensions:CGSizeMake(100, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32];
            [trollsLabel setPosition:ccp(50, 78)];
            [trollBackground addChild:trollsLabel];
            
            CCLabelTTF *trollCountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", trollCount] dimensions:CGSizeMake(50, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32];
            [trollCountLabel setPosition:ccp(50, 38)];
            [trollBackground addChild:trollCountLabel];
            allySlotsUsed++;
        }
        
        if (witchCount > 0){
            CCLayerColor *witchBackground = [CCLayerColor layerWithColor:ccc4(255, 0, 255, 255)];
            [witchBackground setPosition:ccp(70, 240 + ((2 - allySlotsUsed) * 105))];
            [witchBackground setContentSize:CGSizeMake(100, 100)];
            [self addChild:witchBackground];
            
            CCLayerColor *witchDetailBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
            [witchDetailBackground setPosition: ccp(170, 240 + ((2 - allySlotsUsed) * 105))];
            [witchDetailBackground setContentSize:CGSizeMake(200, 100)];
            [self addChild:witchDetailBackground];
            
            CCLabelTTF *witchHealthLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Health: %i", [Witch defaultWitch].maximumHealth] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [witchHealthLabel setColor:ccBLACK];
            [witchHealthLabel setPosition:ccp(100, 78)];
            [witchDetailBackground addChild:witchHealthLabel];
            
            CCLabelTTF *witchDPSLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"DPS: %1.2f", [Witch defaultWitch].dps] dimensions:CGSizeMake(200, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [witchDPSLabel setColor:ccBLACK];
            [witchDPSLabel setPosition:ccp(100, 58)];
            [witchDetailBackground addChild:witchDPSLabel];
            
            
            CCLabelTTF *witchLabel = [CCLabelTTF labelWithString:@"Witches" dimensions:CGSizeMake(100, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:24];
            [witchLabel setPosition:ccp(50, 78)];
            [witchBackground  addChild:witchLabel];
            
            CCLabelTTF *witchCountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i", witchCount] dimensions:CGSizeMake(50, 50) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:32];
            [witchCountLabel setPosition:ccp(50, 38)];
            [witchBackground addChild:witchCountLabel];
            allySlotsUsed++;

        }
        
        
        
    }
    return self;
}

-(void)doneButton{
    GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:self.raid boss:self.boss andPlayer:self.player];
    [gps setLevelNumber:self.levelNumber];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:gps]];
    [gps release];

}
@end
