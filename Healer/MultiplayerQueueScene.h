//
//  MultiplayerQueueScene.h
//  Healer
//
//  Created by Ryan Hart on 7/9/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import <GameKit/GameKit.h>

@interface MultiplayerQueueScene : CCScene <GKMatchmakerViewControllerDelegate, GKMatchDelegate>
@property (nonatomic, retain) UIViewController* presentingViewController;

@end
