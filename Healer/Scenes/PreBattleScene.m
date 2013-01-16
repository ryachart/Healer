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
#import "LevelSelectMapScene.h"
#import "SpellInfoNode.h"
#import "BackgroundSprite.h"
#import "BasicButton.h"
#import "Encounter.h"
#import "ChallengeRatingStepper.h"


#define SPELL_ITEM_TAG 43234

@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, readwrite) BOOL changingSpells;
@property (nonatomic, retain) NSMutableArray *spellInfoNodes;
@property (nonatomic, assign) ChallengeRatingStepper *challengeStepper;


-(void)back;
-(void)changeSpells;
-(void)configureSpells;

@end

@implementation PreBattleScene
@synthesize maxPlayers, levelNumber, spellInfoNodes;
@synthesize changingSpells;

- (void)dealloc {
    [spellInfoNodes release];
    [_player release];
    [_encounter release];
    [super dealloc];
}
- (id)initWithEncounter:(Encounter*)enc andPlayer:(Player*)player {
    if (self = [super init]){
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"pre-battle"] autorelease]];
        
        self.encounter = enc;
        self.player = player;
        self.spellInfoNodes = [NSMutableArray arrayWithCapacity:5];
        
        self.maxPlayers = self.encounter.raid.raidMembers.count; //Assume the number of players in the raid passed in is our max
        
        self.continueButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneButton) andTitle:@"Battle!"];
        CCMenu *doneButton = [CCMenu menuWithItems:self.continueButton, nil];
        [doneButton setPosition:CGPointMake(900, 50)];
        
        [self addChild:doneButton];
        
        if ([PlayerDataManager localPlayer].allOwnedSpells.count > 1) {
            BasicButton *changeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(changeSpells) andTitle:@"Change"];
            [changeButton setScale:.6];
            CCMenu *changeButtonMenu = [CCMenu menuWithItems:changeButton, nil];
            [changeButtonMenu setPosition:CGPointMake(908, 632)];
            [self addChild:changeButtonMenu z:2];
        }
        
        [self configureSpells];
        
        NSMutableDictionary *raidMemberTypes = [NSMutableDictionary dictionaryWithCapacity:5];
        
        for (RaidMember* member in self.encounter.raid.raidMembers){
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
            for (RaidMember *thisMember in self.encounter.raid.raidMembers){
                if ([thisMember.title isEqualToString:types]){
                    member = thisMember; 
                    break;
                }
            }
            RaidMemberPreBattleCard *preBattleCard = [[[RaidMemberPreBattleCard alloc] initWithFrame:CGRectMake(388, 550 - (66 * i), 200, 62) count:[[raidMemberTypes objectForKey:types] intValue] andRaidMember:member] autorelease];
            [self addChild:preBattleCard];
            i++;
        }
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, [CCDirector sharedDirector].winSize.height * .95)];
        [self addChild:backButton];
        
        if (self.encounter.boss.info){
            CCLabelTTF *bossNameLabel = [CCLabelTTF labelWithString:self.encounter.boss.title dimensions:CGSizeMake(300, 200) hAlignment:UITextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:32.0];
            [bossNameLabel setPosition:CGPointMake(200, 520)];
            CCLabelTTF *bossLabel = [CCLabelTTF labelWithString:self.encounter.boss.info dimensions:CGSizeMake(300, 500) hAlignment:UITextAlignmentLeft fontName:@"Cochin-BoldItalic" fontSize:20.0];
            
            [bossLabel setColor:ccc3(88, 54, 22)];
            [bossNameLabel setColor:ccc3(88, 54, 22)];
            [bossLabel setPosition:CGPointMake(200, 90)];
            [self addChild:bossLabel];
            [self addChild:bossNameLabel];
        }
        
        if (enc.levelNumber != 1) {
            self.challengeStepper = [[[ChallengeRatingStepper alloc] initWithEncounter:self.encounter] autorelease];
            [self.challengeStepper setPosition:CGPointMake(480, 20)];
            [self addChild:self.challengeStepper];
        }
        
        if (self.encounter.bossKey) {
            [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:[NSString stringWithFormat:@"assets/%@.plist", self.encounter.bossKey]];
            
            CCSpriteFrame *bossPortraitFrame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"%@_full_portrait.png", self.encounter.bossKey]];
            
            if (bossPortraitFrame) {
                CCSprite *bossPortrait = [CCSprite spriteWithSpriteFrame:bossPortraitFrame];
                [bossPortrait setPosition:CGPointMake(200, 450)];
                [self addChild:bossPortrait];
            }
        }
        
        [[PlayerDataManager localPlayer] setLastSelectedLevel:enc.levelNumber];
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
        [spellInfoNode setPosition:CGPointMake(708, 554 - (95 * i))];
        [self.spellInfoNodes addObject:spellInfoNode];
        [self addChild:spellInfoNode];
        [spellInfoNode release];
        i++;
    }

}

-(void)back{
    if (!self.changingSpells){
        if (self.encounter.bossKey) {
            [[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:[NSString stringWithFormat:@"assets/%@.plist", self.encounter.bossKey]];
        }
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[[[LevelSelectMapScene alloc] init] autorelease]]];
    }
}

-(void)doneButton{
    if (!self.changingSpells){
        GamePlayScene *gps = [[[GamePlayScene alloc] initWithEncounter:self.encounter player:self.player] autorelease];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.5 scene:gps]];
    }
}

-(void)changeSpells{
    if (!self.changingSpells){
        self.changingSpells = YES;
        AddRemoveSpellLayer *arsl = [[AddRemoveSpellLayer alloc] initWithCurrentSpells:self.player.activeSpells];
        [arsl setDelegate:self];
        [arsl setOpacity:0];
        [arsl setScale:0.0];
        [self addChild:arsl z:100];
        [arsl runAction:[CCSpawn actionOne:[CCFadeIn actionWithDuration:.33] two:[CCScaleTo actionWithDuration:.33 scale:1.0]]];
    }
}

-(void)spellSwitchDidCompleteWithActiveSpells:(NSArray *)actives{
    self.player.activeSpells = actives;
    [self configureSpells];
    self.changingSpells = NO;
}

@end
