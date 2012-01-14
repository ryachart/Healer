//
//  BossHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "cocos2d.h"

@interface BossHealthView : CCLayerColor{
	IBOutlet UILabel *bossNameLabel;
	IBOutlet UILabel *healthLabel;
	
	Boss* bossData;
	
}
@property (nonatomic, assign, setter=setBossData:) Boss* bossData;
@property (nonatomic, retain) IBOutlet UILabel *bossNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *healthLabel;

-(void)setBossData:(Boss*)theBoss;
- (id)initWithFrame:(CGRect)frame ;
-(void)updateHealth;

@end
