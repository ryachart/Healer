//
//  GoldCounterSprite.m
//  Healer
//
//  Created by Ryan Hart on 9/2/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "GoldCounterSprite.h"
#import "Shop.h"
#import "PlayerDataManager.h"
#import "CCNumberChangeAction.h"

@interface GoldCounterSprite ()
@property (nonatomic, assign) CCLabelTTF *goldAmountLabel;
@end

@implementation GoldCounterSprite

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)init {
    if (self = [super init]){
        self.updatesAutomatically = YES;
        
        CCSprite *backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"gold_bg.png"];
        [self addChild:backgroundSprite];
        
        NSInteger playerGold = [[PlayerDataManager localPlayer] gold];
        
        self.goldAmountLabel = [GoldCounterSprite goldCostLabelWithCost:playerGold andFontSize:32.0];
        [self.goldAmountLabel setPosition:CGPointMake(60, 20)];
        [backgroundSprite addChild:self.goldAmountLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goldDidChange:) name:PlayerGoldDidChangeNotification object:nil];
    }
    return self;
}

- (void)updateGoldAnimated:(BOOL)animated toGold:(NSInteger)gold
{
    if (animated) {
        [self.goldAmountLabel stopAllActions];
        NSTimeInterval deltaTime = 2.0;
        NSInteger currentGold = self.goldAmountLabel.string.integerValue;
        CCNumberChangeAction *numberChange = [CCNumberChangeAction actionWithDuration:deltaTime fromNumber:currentGold toNumber:gold];
        [self.goldAmountLabel runAction:numberChange];
    } else {
        NSString *labelText = [NSString stringWithFormat:@"%i", gold];
        self.goldAmountLabel.string = labelText;
    }
}

- (void)goldDidChange:(NSNotification*)notif {
    if (self.updatesAutomatically) {
        [self updateGoldAnimated:NO toGold:[[[notif userInfo] objectForKey:PlayerGold] intValue]];
    }
}

+ (CCLabelTTF*)goldCostLabelWithCost:(NSInteger)cost andFontSize:(CGFloat)fontSize{
    NSString *labelText = [NSString stringWithFormat:@"%i", cost];
    CCLabelTTF *goldLabel = [CCLabelTTF labelWithString:labelText dimensions:[[CCSprite spriteWithSpriteFrameName:@"gold_bg.png"] contentSize] hAlignment:UITextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:fontSize];
    [goldLabel setColor:ccc3(241, 181, 123)];
    return goldLabel;
}

+ (CCNode *)goldCostNodeForCost:(NSInteger)cost
{
    CCNode *node = [CCNode node];
    CCLabelTTF *goldLabel = [GoldCounterSprite goldCostLabelWithCost:cost andFontSize:32.0];
    [goldLabel setHorizontalAlignment:UITextAlignmentLeft];
    [node addChild:goldLabel];
    
    CCSprite *goldSprite = [CCSprite spriteWithSpriteFrameName:@"gold_coin.png"];
    [goldSprite setScale:.25];
    [goldSprite setPosition:CGPointMake(-90, 14)];
    [node addChild:goldSprite];
    return node;
}
@end
