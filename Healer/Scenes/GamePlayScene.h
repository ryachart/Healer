//
//  GamePlayScene.h
//  Healer
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "GameObjects.h"
#import "GameUserInterface.h"
#import "AudioController.h"
#import "Encounter.h"

@class Chargable;
/* This is the screen we see while involved in a raid */
@interface GamePlayScene : CCScene {
	NSMutableDictionary *memberToHealthView;
	NSMutableArray *selectedRaidMembers;
	
	//Interface Elements
}
@property (readwrite, retain) Encounter *activeEncounter;
-(id)initWithRaid:(Raid*)raidToUse boss:(Boss*)bossToUse andPlayer:(Player*)playerToUse;

@end
