//
//  BossHealthView.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"

@interface BossHealthView : UIView {
	IBOutlet UILabel *bossNameLabel;
	IBOutlet UILabel *healthLabel;
	
	Boss* bossData;
	
}
@property (assign, setter=setBossData) Boss* bossData;
@property (nonatomic, retain) IBOutlet UILabel *bossNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *healthLabel;

-(void)setBossData:(Boss*)theBoss;

-(void)updateHealth;

@end
