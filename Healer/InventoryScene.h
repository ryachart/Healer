//
//  InventoryScene.h
//  Healer
//
//  Created by Ryan Hart on 5/25/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "cocos2d.h"
#import "IconDescriptionModalLayer.h"

@interface InventoryScene : CCScene <CCTargetedTouchDelegate, IconDescriptorModalDelegate>
@property (nonatomic, readwrite) BOOL returnsToMap;

@end
