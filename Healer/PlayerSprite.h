//
//  PlayerSprite.h
//  Healer
//
//  Created by Ryan Hart on 6/17/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "cocos2d.h"

@interface PlayerSprite : CCSprite
@property (nonatomic, retain) NSArray *equippedItems;
- (id)initWithEquippedItems:(NSArray*)items;
@end
