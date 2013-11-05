//
//  PreBattleScene.m
//  Healer
//
//  Created by Ryan Hart on 3/26/12.
//

#import "PreBattleScene.h"
#import "Player.h"
#import "Enemy.h"
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
#import "GoldCounterSprite.h"
#import "SimpleAudioEngine.h"
#import "PurchaseManager.h"
#import "EncounterDescriptionLayer.h"

#define SPELL_ITEM_TAG 43234
#define ENCOUNTER_INFO_TAG 40328

@interface PreBattleScene ()
@property (nonatomic, readwrite) NSInteger maxPlayers;
@property (nonatomic, readwrite) BOOL changingSpells;
@property (nonatomic, retain) NSMutableArray *spellInfoNodes;
@property (nonatomic, assign) ChallengeRatingStepper *challengeStepper;
@property (nonatomic, assign) CCMenu *backButton;
@property (nonatomic, assign) CCMenu *changeButton;
@property (nonatomic, assign) BasicButton *infoButton;
@end

@implementation PreBattleScene

- (void)dealloc {
    [_spellInfoNodes release];
    [_player release];
    [_encounter release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
- (id)initWithEncounter:(Encounter*)enc andPlayer:(Player*)player {
    if (self = [super init]){
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"pre-battle"] autorelease]];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"assets/postbattle.plist"];
        
        self.encounter = enc;
        self.player = player;
        self.spellInfoNodes = [NSMutableArray arrayWithCapacity:5];
        
        self.maxPlayers = self.encounter.raid.raidMembers.count; //Assume the number of players in the raid passed in is our max
        
        self.continueButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(doneButton) andTitle:@"Battle!"];
        CCMenu *doneButton = [CCMenu menuWithItems:self.continueButton, nil];
        [doneButton setPosition:CGPointMake(900, 50)];
        
        [self addChild:doneButton];
        
         CCLabelTTF *alliesLabel = [CCLabelTTF labelWithString:@"Allies" dimensions:CGSizeMake(300, 200) hAlignment:kCCTextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:64.0];
        [alliesLabel setPosition:CGPointMake(480, 580)];
        [alliesLabel setColor:ccc3(88, 54, 22)];
        [self addChild:alliesLabel];
        
        CCLabelTTF *spellsLabel = [CCLabelTTF labelWithString:@"Spells" dimensions:CGSizeMake(300, 200) hAlignment:kCCTextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:64.0];
        [spellsLabel setPosition:CGPointMake(730, 580)];
        [spellsLabel setColor:ccc3(88, 54, 22)];
        [self addChild:spellsLabel];
        
        if ([PlayerDataManager localPlayer].allOwnedSpells.count > 1) {
            BasicButton *changeButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(changeSpells) andTitle:@"CHANGE"];
            [changeButton setScale:.6];
            self.changeButton = [CCMenu menuWithItems:changeButton, nil];
            [self.changeButton setPosition:CGPointMake(908, 632)];
            [self addChild:self.changeButton z:2];
        }
        
        int noInactives[] = {0,0,0,0};
        [self configureSpellsWithInactiveIndexes:noInactives];
        
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
        
        self.backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [self.backButton setPosition:BACK_BUTTON_POS];
        [self addChild:self.backButton];
        
        GoldCounterSprite *gcs = [[[GoldCounterSprite alloc] init] autorelease];
        [gcs setPosition:CGPointMake(100, 38)];
        [self addChild:gcs z:100];
        
        if (self.encounter.info){
            CCLabelTTF *bossNameLabel = [CCLabelTTF labelWithString:self.encounter.title dimensions:CGSizeMake(300, 200) hAlignment:kCCTextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:32.0];
            [bossNameLabel setPosition:CGPointMake(200, 520)];
            CCLabelTTF *bossLabel = [CCLabelTTF labelWithString:self.encounter.info dimensions:CGSizeMake(300, 500) hAlignment:kCCTextAlignmentCenter fontName:@"Cochin-BoldItalic" fontSize:20.0];
            
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
        
        self.infoButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(showInfo) andTitle:@"LOOT"];
        [self.infoButton setScale:.75];
        
        if (self.encounter.levelNumber > 1 && [PlayerDataManager localPlayer].highestLevelCompleted >= 2) {
            CCMenu *infoMenu = [CCMenu menuWithItems:self.infoButton, nil];
            [infoMenu setPosition:CGPointMake(266, 38)];
            [self addChild:infoMenu];
        }
        
        [[PlayerDataManager localPlayer] setLastSelectedLevel:enc.levelNumber];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expansionPurchased) name:PlayerDidPurchaseExpansionNotification object:nil];
    }
    return self;
}

-(void)configureSpellsWithInactiveIndexes:(int *)inactives {
    for (SpellInfoNode *node in self.spellInfoNodes){
        [node removeFromParentAndCleanup:YES];
    }
    
    [self.spellInfoNodes removeAllObjects];
    
    int spellsUsedIndex = 0;
    for (int i = 0; i < 4; i++) {
            SpellInfoNode *spellInfoNode = nil;
            if (inactives[i] == 1 || spellsUsedIndex >= self.player.activeSpells.count) {
                BOOL locked =  i >= [[PlayerDataManager localPlayer] maximumStandardSpellSlots];
                spellInfoNode = [[SpellInfoNode alloc] initAsEmpty:locked];
                if (locked && ([PlayerDataManager localPlayer].allOwnedSpells.count > 3)) {
                    [spellInfoNode setupUnlockButton];
                }
            } else {
                Spell *activeSpell = [self.player.activeSpells objectAtIndex:spellsUsedIndex];
                spellInfoNode = [[SpellInfoNode alloc] initWithSpell:activeSpell];
                spellsUsedIndex++;
            }
            [spellInfoNode setPosition:CGPointMake(808, 554 - (95 * i))];
            [self.spellInfoNodes addObject:spellInfoNode];
            [self addChild:spellInfoNode];
            [spellInfoNode release];
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

- (void)displayNetworkErrorModal
{
    IconDescriptionModalLayer *networkError = [[[IconDescriptionModalLayer alloc] initAsConfirmationDialogueWithDescription:@"An Internet connection is required to loot chests.  You can fight this battle, but you may not be able to loot the chest at the end without a connection."]autorelease];
    [networkError setDelegate:self];
    [self addChild:networkError z:1000];
}

- (void)beginEncounter
{
    [self.encounter encounterWillBegin];
    
    float playerDamageUpgradesAdjustment = [[PlayerDataManager localPlayer] allyDamageUpgrades] / 100.0f;
    float playerHealthUpgradesAdjustment = [[PlayerDataManager localPlayer] allyHealthUpgrades] / 100.0f;
    
    for (RaidMember *member in self.encounter.raid.raidMembers) {
        Effect *playerUpgradeEffect = [[[Effect alloc] initWithDuration:-1 andEffectType:EffectTypePositiveInvisible] autorelease];
        [playerUpgradeEffect setOwner:self.player];
        [playerUpgradeEffect setTitle:@"player-upgrade-eff"];
        [playerUpgradeEffect setDamageDoneMultiplierAdjustment:playerDamageUpgradesAdjustment];
        [playerUpgradeEffect setMaximumHealthMultiplierAdjustment:playerHealthUpgradesAdjustment];
        [member addEffect:playerUpgradeEffect];
        member.health = member.maximumHealth;
    }
    
    [[SimpleAudioEngine sharedEngine] crossFadeBackgroundMusic:self.encounter.battleTrackTitle forDuration:1.5];
    GamePlayScene *gps = [[[GamePlayScene alloc] initWithEncounter:self.encounter player:self.player] autorelease];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.5 scene:gps]];
}

-(void)doneButton{
    if (!self.changingSpells){
        if (self.encounter.levelNumber >= 22 && self.encounter.difficulty == 5) {
            //This encounter is unavailable on Brutal
            IconDescriptionModalLayer *modalLayer = [[[IconDescriptionModalLayer alloc] initWithIconName:nil title:@"Unavailable" andDescription:@"This battle is unavailable on Brutal difficulty.  Please check back in a future update."] autorelease];
            [modalLayer setDelegate:self];
            [self addChild:modalLayer];
        } else if ([PlayerDataManager localPlayer].isInventoryFull) {
            IconDescriptionModalLayer *fullInventory = [[[IconDescriptionModalLayer alloc] initAsConfirmationDialogueWithDescription:@"Your inventory is full and you will be unable to receive loot."]autorelease];
            [fullInventory setDelegate:self];
            [self addChild:fullInventory z:1000];
        } else {
            [self beginEncounter];
        }
    }
}

-(void)changeSpells{
    if (!self.changingSpells){
        self.changingSpells = YES;
        [self.changeButton setVisible:NO];
        AddRemoveSpellLayer *arsl = [[AddRemoveSpellLayer alloc] initWithCurrentSpells:self.player.activeSpells];
        [arsl setDelegate:self];;
        [self addChild:arsl z:100];
    }
}

- (void)spellSwitchDidChangeToActiveSpells:(NSArray *)actives andInactiveIndexes:(int *)inactives
{
    self.player.activeSpells = actives;
    [self configureSpellsWithInactiveIndexes:inactives];
}

-(void)spellSwitchDidCompleteWithActiveSpells:(NSArray *)actives andInactiveIndexes:(int *)inactives {
    int noInactives[] = {0,0,0,0};
    [self configureSpellsWithInactiveIndexes:noInactives];
    self.changingSpells = NO;
    [self.changeButton setVisible:YES];
}

- (void)showInfo
{
    EncounterDescriptionLayer *edl = [[[EncounterDescriptionLayer alloc] initWithEncounter:self.encounter] autorelease];
    [self addChild:edl z:3 tag:ENCOUNTER_INFO_TAG];
}

#pragma mark - Icon Description Modal Layer

- (void)iconDescriptionModalDidComplete:(id)modal
{
    IconDescriptionModalLayer *completedModal = (IconDescriptionModalLayer*)modal;
    [completedModal removeFromParentAndCleanup:YES];
    
    if (completedModal.isConfirmed) {
        [self beginEncounter];
    }
}

#pragma mark - Notifications

- (void)expansionPurchased
{
    int noInactives[] = {0,0,0,0};
    [self configureSpellsWithInactiveIndexes:noInactives];
}

@end
