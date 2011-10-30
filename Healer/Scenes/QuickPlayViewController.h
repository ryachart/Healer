//
//  QuickPlayViewController.h
//  RaidLeader
//
//  Created by Ryan Hart on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameObjects.h"
#import "InGameViewController.h"

@interface QuickPlayViewController : UIViewController {

}
-(IBAction)startEasyGame;
-(IBAction)startMediumGame;
-(IBAction)startHardGame;
-(IBAction)startExtremeGame;
-(IBAction)back;
@end
