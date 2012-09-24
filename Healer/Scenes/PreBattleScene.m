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
#import "LevelSelectScene.h"
#import "SpellInfoNode.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"


#define SPELL_ITEM_TAG 43234

@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, readwrite) BOOL changingSpells;
@property (nonatomic, retain) NSMutableArray *spellInfoNodes;


-(void)back;
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
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        self.raid = raid;
        self.player = player;
        self.boss = boss;
        self.spellInfoNodes = [NSMutableArray arrayWithCapacity:5];
        
        self.maxPlayers = raid.raidMembers.count; //Assume the number of players in the raid passed in is our max
        
        self.continueButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneButton) andTitle:@"Battle!"];
        CCMenu *doneButton = [CCMenu menuWithItems:self.continueButton, nil];
        [doneButton setPosition:CGPointMake(900, 50)];
        
        [self addChild:doneButton];
        
        CCLabelTTF *changeLabel = [CCLabelTTF labelWithString:@"Change Spells" fontName:@"Arial" fontSize:24.0];
        [changeLabel setColor:ccBLUE];
        CCMenu *changeButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:changeLabel target:self selector:@selector(changeSpells)], nil];
        [changeButton setPosition:CGPointMake(900, 650)];
        [self addChild:changeButton z:2];
        
        CCLabelTTF *activeSpellsLabel = [CCLabelTTF labelWithString:@"Spells:" fontName:@"Arial" fontSize:32];
        [activeSpellsLabel setPosition:CGPointMake([CCDirector sharedDirector].winSize.width * .75, [CCDirector sharedDirector].winSize.height * .85)];
        [self addChild:activeSpellsLabel];
        
        [self configureSpells];

        CCLabelTTF *alliesLabel = [CCLabelTTF labelWithString:@"Your Allies:" fontName:@"Arial" fontSize:32];
        [alliesLabel setPosition:ccp(120, 664)];
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
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, [CCDirector sharedDirector].winSize.height * .95)];
        [self addChild:backButton];
        
        if (boss.info){
            CCLabelTTF *yourEnemyLAbel = [CCLabelTTF labelWithString:@"Your Enemy:" fontName:@"Arial" fontSize:32.0];
            CCLabelTTF *bossNameLabel = [CCLabelTTF labelWithString:self.boss.title dimensions:CGSizeMake(300, 200) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32.0];
            [yourEnemyLAbel setPosition:CGPointMake(520, 600)];
            [bossNameLabel setPosition:CGPointMake(520, 480)];
            CCLabelTTF *bossLabel = [CCLabelTTF labelWithString:self.boss.info dimensions:CGSizeMake(300, 500) hAlignment:UITextAlignmentLeft fontName:@"Arial" fontSize:16.0];
            
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
    if (!self.changingSpells){
        [[CCDirector sharedDirector] replaceScene:[CCTransitionSlideInL transitionWithDuration:1.0 scene:[[[LevelSelectScene alloc] init] autorelease]]];
    }
}

-(void)doneButton{
    if (!self.changingSpells){
        GamePlayScene *gps = [[[GamePlayScene alloc] initWithRaid:self.raid boss:self.boss andPlayer:self.player] autorelease];
        [gps setLevelNumber:self.levelNumber];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.5 scene:gps]];
    }
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
