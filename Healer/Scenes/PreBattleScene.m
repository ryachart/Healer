//
//  PreBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//

#import "PreBattleScene.h"
#import "Player.h"
#import "Boss.h"
#import "Raid.h"
#import "Spell.h"
#import "GamePlayScene.h"
#import "RaidMemberPreBattleCard.h"
#import "QuickPlayScene.h"
#import "SpellInfoNode.h"
#import "BackgroundSprite.h"

#define SPELL_ITEM_TAG 43234

@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, readwrite) BOOL changingSpells;
@property (nonatomic, retain) NSMutableArray *spellInfoNodes;
@property (nonatomic, retain) Player *player;
@property (nonatomic, retain) Boss *boss;
@property (nonatomic, retain) Raid *raid;

-(void)back;
-(void)doneButton;
-(void)changeSpells;
-(void)configureSpells;

@end

@implementation PreBattleScene
@synthesize raid = _raid, boss = _boss, player = _player, maxPlayers, levelNumber, spellInfoNodes;
@synthesize changingSpells;

- (void)dealloc {
    [spellInfoNodes release];
    [_player release];
    [_boss release];
    [_raid release];
    [super dealloc];
}
-(id)initWithRaid:(Raid*)raid boss:(Boss*)boss andPlayer:(Player*)player{
    if (self = [super init]){
        [self addChild:[[[BackgroundSprite alloc] initWithAssetName:@"wood-bg-ipad"] autorelease]];
        self.raid = raid;
        self.player = player;
        self.boss = boss;
        self.spellInfoNodes = [NSMutableArray arrayWithCapacity:5];
        
        self.maxPlayers = raid.raidMembers.count; //Assume the number of players in the raid passed in is our max
        
        CCMenu *doneButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Battle!" fontName:@"Arial" fontSize:32] target:self selector:@selector(doneButton)], nil];
        [doneButton setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .8, [CCDirector sharedDirector].winSize.height * .05 )];
        
        [self addChild:doneButton];
        
        CCLabelTTF *changeLabel = [CCLabelTTF labelWithString:@"Change Spells" fontName:@"Arial" fontSize:24.0];
        [changeLabel setColor:ccBLUE];
        CCMenu *changeButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:changeLabel target:self selector:@selector(changeSpells)], nil];
        [changeButton setPosition:CGPointMake(900, 650)];
        [self addChild:changeButton z:2];
        
        CCLayerColor *spellsGroupingBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255)];
        [spellsGroupingBackground setPosition:ccp([CCDirector sharedDirector].winSize.width * .7, [CCDirector sharedDirector].winSize.height * .25)];
        [spellsGroupingBackground setContentSize:CGSizeMake(298,500)];
        [self addChild:spellsGroupingBackground];
        
        
        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Spells:" fontName:@"Arial" fontSize:32];
        [activeSpellsLabel  setColor:ccBLACK];
        [activeSpellsLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .75, [CCDirector sharedDirector].winSize.height * .85)];
        [self addChild:activeSpellsLabel];
        
        [self configureSpells];

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
        
        int i = 0;
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
            CCLabelTTF *bossNameLabel = [CCLabelTTF labelWithString:self.boss.title dimensions:CGSizeMake(300, 200) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
            [yourEnemyLAbel setPosition:CGPointMake(520, 600)];
            [bossNameLabel setPosition:CGPointMake(520, 480)];
            CCLabelTTF *bossLabel = [CCLabelTTF labelWithString:self.boss.info dimensions:CGSizeMake(300, 500) alignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16.0];
            
            [bossLabel setPosition:CGPointMake(525, 250)];
            [self addChild:bossLabel];
            [self addChild:yourEnemyLAbel];
            [self addChild:bossNameLabel];
        }
        
    }
    return self;
}

-(void)configureSpells{
    for (SpellInfoNode *node in self.spellInfoNodes){
        [node removeFromParentAndCleanup:YES];
    }
    
    [self.spellInfoNodes removeAllObjects];
    
    int i = 0;
    for (Spell *activeSpell in self.player.activeSpells){
        SpellInfoNode *spellInfoNode = [[SpellInfoNode alloc] initWithSpell:activeSpell];
        [spellInfoNode setPosition:CGPointMake(716, 530 - (105 * i))];
        [self.spellInfoNodes addObject:spellInfoNode];
        [self addChild:spellInfoNode];
        [spellInfoNode release];
        i++;
    }

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

-(void)changeSpells{
    if (!self.changingSpells){
        self.changingSpells = YES;
        AddRemoveSpellLayer *arsl = [[AddRemoveSpellLayer alloc] initWithCurrentSpells:self.player.activeSpells];
        [arsl setPosition:CGPointMake(-1024, 0)];
        [arsl setDelegate:self];
        [self addChild:arsl z:100];
        [arsl runAction:[CCMoveTo actionWithDuration:.5 position:CGPointMake(0, 0)]];
    }
}

-(void)spellSwitchDidCompleteWithActiveSpells:(NSArray *)actives{
    self.player.activeSpells = actives;
    [self configureSpells];
    self.changingSpells = NO;
}

@end
