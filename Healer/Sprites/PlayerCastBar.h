//
//  PlayerCastBar.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PlayerCastBar : UIView {
	UILabel* timeRemaining;
	
	double percentTimeRemaining;
}

-(void)updateTimeRemaining:(NSTimeInterval)remaining ofMaxTime:(NSTimeInterval)maxTime;
@end
