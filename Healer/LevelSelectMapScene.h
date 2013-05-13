//
//  LevelSelectMapScene.h
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "cocos2d.h"
#import "LevelSelectMapNode.h"

@interface LevelSelectMapScene : CCScene <LevelSelectMapNodeDelegate, UIAlertViewDelegate>
@property (nonatomic, readwrite) BOOL comingFromVictory;
@end
