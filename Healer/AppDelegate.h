//
//  AppDelegate.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"
#import "HealerStartScene.h"

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *viewController;
@end
