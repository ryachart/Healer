//
//  DivinityConfigScene.h
//  Healer
//
//  Created by Ryan Hart on 6/30/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "Talents.h"
#import "TalentTierCard.h"
#import "IconDescriptionModalLayer.h"

@class TalentTierCard;
@interface TalentScene : CCScene <TalentTierCardDelegate, IconDescriptorModalDelegate> {
    TalentTierCard *tierTableCards[NUM_DIV_TIERS];
    CCSprite *chargedPipes[NUM_DIV_TIERS];
    CCSprite *iconSprites[NUM_DIV_TIERS][3];
    CCMenu *buttonSprites[NUM_DIV_TIERS][3];
}

@end
