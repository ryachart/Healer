//
//  TreasureChest.m
//  Healer
//
//  Created by Ryan Hart on 6/25/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "TreasureChest.h"
#import "EquipmentItem.h"
#import "ItemDescriptionNode.h"

#define TREASURE_CHEST_FRAMES 12

#define BASE_Z 10
#define ITEM_Z 5
#define TOP_Z 1

@interface TreasureChest ()
@property (nonatomic, assign) CCSprite *base;
@property (nonatomic, assign) CCSprite *top;
@property (nonatomic, assign) CCSprite *itemIconSprite;
@property (nonatomic, assign) ItemDescriptionNode *itemDescNode;
@end

@implementation TreasureChest


- (id)init
{
    if (self = [super init]) {
        self.base = [CCSprite spriteWithSpriteFrameName:@"treasurechest_base.png"];
        [self addChild:self.base z:BASE_Z];
        
        self.top = [CCSprite spriteWithSpriteFrameName:@"treasurechest_top01.png"];
        [self addChild:self.top z:TOP_Z];
    }
    return self;
}

- (void)open
{
    [self.top runAction:[CCAnimate actionWithAnimation:[TreasureChest openingAnimation]]];
}

- (void)openWithItem:(EquipmentItem *)item
{
    self.itemIconSprite = [CCSprite spriteWithSpriteFrameName:item.itemSpriteName];
    self.itemIconSprite.opacity = 0;
    [self addChild:self.itemIconSprite z:ITEM_Z];
    
    self.itemDescNode = [[[ItemDescriptionNode alloc] init] autorelease];
    self.itemDescNode.opacity = 0;
    [self.itemDescNode setItem:item];
    [self addChild:self.itemDescNode];
    
    CCAnimation *openingAnimation = [TreasureChest openingAnimation];
    
    __block TreasureChest *blockSelf = self;
    [self.itemIconSprite runAction:[CCSequence actions:[CCDelayTime actionWithDuration:openingAnimation.duration], [CCFadeTo actionWithDuration:1.0 opacity:255], [CCEaseBackIn actionWithAction:[CCMoveBy actionWithDuration:.75 position:CGPointMake(0, 60)]], [CCCallBlockN actionWithBlock:^(CCNode *node){
            [blockSelf reorderChild:blockSelf.itemIconSprite z:BASE_Z+1];
    }], [CCEaseIn actionWithAction:[CCMoveBy actionWithDuration:.75 position:CGPointMake(0, -60)] rate:1.0],
        [CCCallBlockN actionWithBlock:^(CCNode *node){
        [blockSelf.top runAction:[CCFadeOut actionWithDuration:1.0]];
        [blockSelf.base runAction:[CCFadeOut actionWithDuration:1.0]];
    }], [CCDelayTime actionWithDuration:.5],
        [CCMoveBy actionWithDuration:.75 position:CGPointMake(-150, 0)],
        [CCCallBlockN actionWithBlock:^(CCNode *node){
        [blockSelf.itemDescNode runAction:[CCFadeTo actionWithDuration:1.0 opacity:255]];
    }],
    nil]];
    
    [self.top runAction:[CCAnimate actionWithAnimation:openingAnimation]];
}

+ (CCAnimation *)openingAnimation
{
    NSMutableArray *animationFrames = [NSMutableArray arrayWithCapacity:TREASURE_CHEST_FRAMES];
    
    for (int i = 0; i < TREASURE_CHEST_FRAMES; i++) {
        [animationFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"treasurechest_top%02d.png", i+1]]];
    }
    
    CCAnimation *openAnimation = [CCAnimation animationWithSpriteFrames:animationFrames delay:2.0/60.0];
    openAnimation.restoreOriginalFrame = NO;
    return openAnimation;
}

@end
