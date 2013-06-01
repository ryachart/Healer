//
//  StaminaCounterNode.m
//  Healer
//
//  Created by Ryan Hart on 5/29/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "StaminaCounterNode.h"
#import "CCLabelTTFShadow.h"
#import "PlayerDataManager.h"

@interface StaminaCounterNode ()
@property (nonatomic, assign) CCLabelTTFShadow *counterLabel;
@property (nonatomic, assign) CCLabelTTFShadow *nextLabel;
@property (nonatomic, readwrite) BOOL staminaChecked;
@end

@implementation StaminaCounterNode

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)init
{
    if (self = [super initWithSpriteFrameName:@"counter_bg.png"]) {
        
        CCSprite *key = [CCSprite spriteWithSpriteFrameName:@"key.png"];
        [key setScale:.5];
        [key setPosition:CGPointMake(40, 32)];
        [self addChild:key];
        
        self.counterLabel = [CCLabelTTFShadow labelWithString:@"" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        [self.counterLabel setPosition:CGPointMake(106, 32)];
        [self addChild:self.counterLabel];
        
        self.nextLabel = [CCLabelTTFShadow labelWithString:@"..." fontName:@"TrebuchetMS-Bold" fontSize:16.0];
        [self.nextLabel setPosition:CGPointMake(self.contentSize.width / 2, self.contentSize.height + 10)];
        [self addChild:self.nextLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCounter) name:PlayerStaminaDidChangeNotification object:nil];
        
        [self updateCounter];
        [self schedule:@selector(updateCounter) interval:1.0];
        self.staminaChecked = NO;
    }
    return self;
}

- (void)updateCounter
{
    if ([PlayerDataManager localPlayer].stamina == STAMINA_NOT_LOADED) {
        self.counterLabel.string = @"...";
        self.nextLabel.string = @"...";
    } else {
        
        self.counterLabel.string = [NSString stringWithFormat:@"%i/%i", [PlayerDataManager localPlayer].stamina, [PlayerDataManager localPlayer].maxStamina];
        if ([PlayerDataManager localPlayer].stamina == [PlayerDataManager localPlayer].maxStamina) {
            self.nextLabel.visible = NO;
        } else {
            self.nextLabel.visible = YES;
            NSInteger secondsUntil =  [PlayerDataManager localPlayer].secondsUntilNextStamina;
            self.nextLabel.string = [NSString stringWithFormat:@"Next in %d:%2d:%02d", secondsUntil / 3600, secondsUntil / 60 % 60, secondsUntil % 60];
        }
    }
    
    if ([PlayerDataManager localPlayer].secondsUntilNextStamina <= 0 && [PlayerDataManager localPlayer].secondsUntilNextStamina != STAMINA_NOT_LOADED) {
        if (!self.staminaChecked) {
            [[PlayerDataManager localPlayer]  checkStamina];
            self.staminaChecked = YES;
        }
    } else {
        self.staminaChecked = NO;
    }
}
@end
