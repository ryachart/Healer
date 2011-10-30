//
//  HelloWorldLayer.m
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright Apple 2011. All rights reserved.
//


// Import the interfaces
#import "EncounterScene.h"
#import "AssetManager.h"
#import "Ally.h"
#import "Assassin.h"
#import "Guardian.h"
#import "Cleric.h"
#import "Wizard.h"
#import "Grozog.h"
#import "Boss.h"

// HelloWorldLayer implementation
@implementation EncounterScene

@synthesize plistDefaults;
@synthesize encounter;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	EncounterScene *layer = [EncounterScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    plistDefaults = [[AssetManager sharedInstance] getDefaults];
    
    NSMutableDictionary *bgColor = [plistDefaults valueForKey:@"background_color"];
	if( (self=[super initWithColor:ccc4([[bgColor objectForKey:@"r"] intValue], [[bgColor valueForKey:@"g"] intValue], [[bgColor valueForKey:@"b"] intValue], 255)] )) {
        
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        self.encounter = [[Encounter alloc] init];
        
        for(int i = 0; i < [[plistDefaults valueForKey:@"num_allies_assassins"] intValue]; i++)
        {
            Assassin *newAlly = [Assassin spriteWithFile:@"Assassin.PNG" rect:CGRectMake(0, 0, 50, 55)];
            newAlly.position = ccp(newAlly.contentSize.width/2 + 250, winSize.height/2 - 200 + 100*i);
            [self addChild:newAlly];
            [encounter addAlly:newAlly];
        }
        
        for(int i = 0; i < [[plistDefaults valueForKey:@"num_allies_guardians"] intValue]; i++)
        {
            Guardian *newAlly = [Guardian spriteWithFile:@"Guardian.PNG" rect:CGRectMake(0, 0, 70, 55)];
            newAlly.position = ccp(newAlly.contentSize.width/2 + 350, winSize.height/2 + 100*i);
            [self addChild:newAlly];
            [encounter addAlly:newAlly];
        }

        for(int i = 0; i < [[plistDefaults valueForKey:@"num_allies_wizards"] intValue]; i++)
        {
            Wizard *newAlly = [Wizard spriteWithFile:@"Wizard.PNG" rect:CGRectMake(0, 0, 50, 59)];
            newAlly.position = ccp(newAlly.contentSize.width/2 + 150, winSize.height/2 - 200 + 100*i);
            [self addChild:newAlly];
            [encounter addAlly:newAlly];
        }
        
        for(int i = 0; i < [[plistDefaults valueForKey:@"num_allies_clerics"] intValue]; i++)
        {
            Cleric *newAlly = [Cleric spriteWithFile:@"Cleric.PNG" rect:CGRectMake(0, 0, 50, 72)];
            newAlly.position = ccp(newAlly.contentSize.width/2 + 50, winSize.height/2 + 100*i);
            [self addChild:newAlly];
            [encounter addAlly:newAlly];
        }
        
        for(int i = 0; i < [[plistDefaults valueForKey:@"num_bosses"] intValue]; i++)
        {
            Grozog *newBoss = [Grozog spriteWithFile:@"Grozog.png" rect:CGRectMake(0, 0, 441, 320)];
            newBoss.position = ccp(newBoss.contentSize.width/2 + 550, winSize.height/2 + 100*i);
            [self addChild:newBoss];
            [encounter addBoss:newBoss];
        }


        
	}
    
    [self schedule:@selector(takeDamage:) interval:0.5f];
    
	return self;
}

-(void) takeDamage: (ccTime) dt
{
    for(Ally *ally in encounter.allies)
    {
        ally.health -= 5;
        [ally updateHealthBar];
    }
    for(Boss *boss in encounter.bosses)
    {
        boss.health -= 50;
        [boss updateHealthBar];
    }
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
