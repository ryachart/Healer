//
//  PlayerCastBar.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <cocos2d.h>

@class Spell;
@interface PlayerCastBar : CCLayer <CCRGBAProtocol> {
	double percentTimeRemaining;
}
@property (nonatomic, assign) CCLabelTTF *timeRemaining;
@property (nonatomic, assign) CCLabelTTF *timeRemainingShadow;
@property (nonatomic, assign) CCSprite *castBar;

-(id)initWithFrame:(CGRect)frame;
-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime forSpell:(Spell*)spell;
@end
