//
//  AppDelegate.h
//  RaidLeader
//
//  Created by Ryan Hart on 7/4/11.
//  Copyright Apple 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
