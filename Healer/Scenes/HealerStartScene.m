//
//  HealerStartScene.m
//  Healer
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "HealerStartScene.h"

@interface HealerStartScene ()
@property (retain) CCMenu* menu;
@property (retain) CCMenuItemLabel* storyModeButton;
@property (retain) CCMenuItemLabel* quickPlayButton;

-(void)quickPlaySelected;
-(void)settingsSelected;

@end

@implementation HealerStartScene
@synthesize menu;
@synthesize storyModeButton;
@synthesize quickPlayButton;

-(id)init{
    if (self = [super init]){
        //Perform Scene Setup
        
//        self.storyModeButton = [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Story Mode" fontName:@"Arial" fontSize:32] target:self selector:@selector(storyModeSelected)] autorelease];
        self.quickPlayButton= [[[CCMenuItemLabel alloc] initWithLabel:[CCLabelTTF labelWithString:@"Play" fontName:@"Arial" fontSize:32] target:self selector:@selector(quickPlaySelected)] autorelease];
        [self.quickPlayButton setPosition:ccp(0, 100)];
        
        self.menu = [CCMenu menuWithItems:self.quickPlayButton, nil];
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        [self.menu setPosition:ccp(winSize.width * .5, winSize.height * 1/3)];
        [self.menu setColor:ccc3(255, 255, 255)];
        [self addChild:self.menu];
        
        
    }
    return self;
}


-(void)quickPlaySelected
{
	QuickPlayScene *qpS = [QuickPlayScene new];
	[[CCDirector sharedDirector] pushScene:qpS];
	[qpS release];
}

-(void)settingsSelected
{
	//No behavior defined yet.
}


- (void)dealloc {
    self.menu = nil;
    self.storyModeButton = nil;
    self.quickPlayButton = nil;
    [super dealloc];
}

@end
