//
//  LevelSelectMapScene.h
//  Healer
//
//  Created by Ryan Hart on 10/25/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "LevelSelectMapNode.h"
#import "IconDescriptionModalLayer.h"

@interface LevelSelectMapScene : CCScene <LevelSelectMapNodeDelegate, UIAlertViewDelegate, IconDescriptorModalDelegate>
@property (nonatomic, readwrite) BOOL comingFromVictory;
@end
