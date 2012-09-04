//
//  GoldCounterSprite.m
//  Healer
//
//  Created by Ryan Hart on 9/2/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "GoldCounterSprite.h"
#import "Shop.h"

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
        CCSprite *backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"gold_bg.png"];
        [self addChild:backgroundSprite];
        
        NSInteger playerGold = [Shop localPlayerGold];
        
        self.goldAmountLabel = [GoldCounterSprite goldCostLabelWithCost:playerGold andFontSize:32.0];
        [self.goldAmountLabel setPosition:CGPointMake(50, 20)];
        [backgroundSprite addChild:self.goldAmountLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goldDidChange:) name:PlayerGoldDidChangeNotification object:nil];
    }
    return self;
}

- (void)goldDidChange:(NSNotification*)notif {
    NSInteger playerGold = [[[notif userInfo] objectForKey:PlayerGold] intValue];
    NSString *labelText = [NSString stringWithFormat:@"%i", playerGold];
    self.goldAmountLabel.string = labelText;
}

+ (CCLabelTTF*)goldCostLabelWithCost:(NSInteger)cost andFontSize:(CGFloat)fontSize{
    NSString *labelText = [NSString stringWithFormat:@"%i", cost];
    CCLabelTTF *goldLabel = [CCLabelTTF labelWithString:labelText dimensions:[[CCSprite spriteWithSpriteFrameName:@"gold_bg.png"] contentSize] alignment:UITextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:fontSize];
    [goldLabel setColor:ccc3(241, 181, 123)];
    return goldLabel;
}
@end