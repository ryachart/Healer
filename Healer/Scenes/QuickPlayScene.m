//
//  QuickPlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayScene.h"
#import "PersistantDataManager.h"
#import "PreBattleScene.h"
#import "HealerStartScene.h"
#import "Encounter.h"
#import "Shop.h"

#define NUM_ENCOUNTERS 9

@interface QuickPlayScene ()
@property (retain) CCMenu *menu;

-(void)beginGameWithSelectedLevel:(id)sender;
-(void)back;

@end

@implementation QuickPlayScene
@synthesize menu;
-(id)init{
    if (self = [super init]){
#if DEBUG
//        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:100] forKey:PlayerHighestLevelCompleted];
#endif
        self.menu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < NUM_ENCOUNTERS; i++){
            CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %i", i + 1] fontName:@"Arial" fontSize:32] target: self selector:@selector(beginGameWithSelectedLevel:)];
            levelButton.tag = i +1;
            if (i > ([[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue] )){
                levelButton.opacity = 125;
            }
            [self.menu addChild:levelButton];
        }
        [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height / 2)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self.menu alignItemsInRows:[NSNumber numberWithInt:NUM_ENCOUNTERS]/*,[NSNumber numberWithInt:10]*/, nil];
        [self addChild:self.menu];
        
        
        CCMenu *backButton = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Back" fontName:@"Arial" fontSize:24.0] target:self selector:@selector(back)], nil];
        [backButton setPosition:CGPointMake(30, [CCDirector sharedDirector].winSize.height * .9)];
        [backButton setColor:ccWHITE];
        [self addChild:backButton];
    }
    return self;
}


-(void)beginGameWithSelectedLevel:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    srand(time(NULL));
    
    int highestCompleted = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
    
    if (highestCompleted + 1 < level){
        return;
    }
    
    Encounter *encounter = [Encounter encounterForLevel:level isMultiplayer:NO];
    Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:1000 energyRegen:10];
    NSMutableArray *activeSpells = [NSMutableArray arrayWithCapacity:4];
    for (Spell *spell in encounter.recommendedSpells){
        if ([Shop playerHasSpell:spell]){
            [activeSpells addObject:[[spell class] defaultSpell]];
        }
    }
    [basicPlayer setActiveSpells:(NSArray*)activeSpells];
    
    if (encounter.boss && basicPlayer && encounter.raid){
        
        PreBattleScene *pbs = [[PreBattleScene alloc] initWithRaid:encounter.raid boss:encounter.boss andPlayer:basicPlayer];
        [pbs setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFlipAngular transitionWithDuration:1.0 scene:pbs]];
        [pbs release];

    }
    [basicPlayer release];
}

-(void)back
{
    [[CCDirector sharedDirector] replaceScene:[[[HealerStartScene alloc] init] autorelease]];
}


- (void)dealloc {
    [super dealloc];
}


@end
