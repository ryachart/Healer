//
//  DivinityConfigScene.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "Divinity.h"
#import "DivinityTierCard.h"
#import "ViewDivinityChoiceLayer.h"

@class DivinityTierCard;
@interface DivinityConfigScene : CCScene <DivinityTierCardDelegate, ViewDivinityChoiceLayerDelegate> {
    DivinityTierCard *tierTableCards[NUM_DIV_TIERS];
    CCSprite *chargedPipes[NUM_DIV_TIERS];
    CCSprite *iconSprites[NUM_DIV_TIERS][3];
    CCMenu *buttonSprites[NUM_DIV_TIERS][3];
}

@end
