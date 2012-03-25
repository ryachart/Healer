//
//  QuickPlayScene.m
//  Healer
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QuickPlayScene.h"
#import "PersistantDataManager.h"

@interface QuickPlayScene ()
@property (retain) CCMenuItemLabel *easyModeButton;
@property (retain) CCMenuItemLabel *mediumModeButton;
@property (retain) CCMenuItemLabel *hardModeButton;
@property (retain) CCMenuItemLabel *extremeModeButton;
@property (retain) CCMenu *menu;

-(void)beginGameWithSelectedLevel:(id)sender;

-(void)back;

@end

@implementation QuickPlayScene
@synthesize easyModeButton;
@synthesize mediumModeButton;
@synthesize hardModeButton;
@synthesize extremeModeButton;
@synthesize menu;
-(id)init{
    if (self = [super init]){
        self.menu = [CCMenu menuWithItems:nil];
        for (int i = 0; i < 20; i++){
            CCMenuItemLabel *levelButton = [[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:[NSString stringWithFormat:@"Level %i", i + 1] fontName:@"Arial" fontSize:32] target: self selector:@selector(beginGameWithSelectedLevel:)];
            levelButton.tag = i +1;
            if (i > ([[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue] )){
                levelButton.opacity = 125;
            }
            [self.menu addChild:levelButton];
        }
        [self.menu setPosition:ccp([CCDirector sharedDirector].winSize.width /2, [CCDirector sharedDirector].winSize.height / 2)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self.menu alignItemsInRows:[NSNumber numberWithInt:10],[NSNumber numberWithInt:10], nil];
        [self addChild:self.menu];
    }
    return self;
}


-(void)beginGameWithSelectedLevel:(CCMenuItemLabel*)sender{
    int level = sender.tag;
    srand(time(NULL));
    
    int i = [[[NSUserDefaults standardUserDefaults] objectForKey:PlayerHighestLevelCompleted] intValue];
    
    if (i + 1 < level){
        return;
    }
    
    if (level == 1){
        Raid *basicRaid = [[Raid alloc] init];
        Player *basicPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
        Boss *basicBoss = [[Boss alloc] initWithHealth:5000 damage:12 targets:1 frequency:1.5 andChoosesMT:NO];
        
        [basicPlayer setActiveSpells:[NSArray arrayWithObjects:[Heal defaultSpell], nil]];
        
        for (int i = 0; i < 2; i++){
            [basicRaid addRaidMember:[Troll defaultTroll]];
        }
        GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:basicRaid boss:basicBoss andPlayer:basicPlayer];
        [gps setLevelNumber:level];
        [[CCDirector sharedDirector] replaceScene:gps];
        [gps release];
        [basicBoss release];
        [basicPlayer release];
        [basicRaid release];
    }
    
}

-(void)startEasyGame
{
	
	
	Raid* demoRaid = [[Raid alloc] init];
	Player* demoPlayer = [[Player alloc] initWithHealth:100 energy:100 energyRegen:1];
	Giant* demoBoss = 	[Giant defaultBoss];

	[demoPlayer setActiveSpells:[NSArray arrayWithObjects:[SurgingGrowth defaultSpell], [RoarOfLife defaultSpell], [FieryAdrenaline defaultSpell], [WoundWeaving defaultSpell], nil]];
	
	for (int i = 0; i < 5; i++){
		[demoRaid addRaidMember:[Witch defaultWitch]];
	}
	for (int i = 0; i < 10; i++){
		[demoRaid addRaidMember:[Ogre defaultOgre]];
	}
	for (int i =0; i < 10; i++){
		[demoRaid addRaidMember:[Troll defaultTroll]];
	}
	
//	
//	InGameViewController* demoGameVC = [[InGameViewController alloc] initWithNibName:@"InGameViewController" bundle:nil];
//	[demoGameVC readyWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
	
	//[self.navigationController pushViewController:demoGameVC animated:YES];
	GamePlayScene *gps = [[GamePlayScene alloc] initWithRaid:demoRaid boss:demoBoss andPlayer:demoPlayer];
    [[CCDirector sharedDirector] replaceScene:gps];
	
}

-(void)back
{
	//[self.navigationController popViewControllerAnimated:YES];
}


- (void)dealloc {
    [super dealloc];
}


@end
