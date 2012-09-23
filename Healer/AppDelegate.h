//
//  AppDelegate.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//

#import <UIKit/UIKit.h>
#import "HealerStartScene.h"
#import "cocos2d.h"

@interface AppDelegate : NSObject <UIApplicationDelegate, CCDirectorDelegate>
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navController;
@end
