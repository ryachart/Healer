//
//  EncounterScene.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright Apple 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Encounter.h"

// HelloWorldLayer
@interface EncounterScene : CCLayerColor
{
    NSMutableDictionary *plistDefaults; //The AssetManager is already caching the plists.  We don't need to cache them in the scene
    
    Encounter *encounter;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property(nonatomic, retain) NSMutableDictionary *plistDefaults;
@property(nonatomic, retain) Encounter *encounter;

@end
