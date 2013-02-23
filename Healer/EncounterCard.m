//
//  EncounterCard.m
//  Healer
//
//  Created by Ryan Hart on 10/29/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "EncounterCard.h"
#import "Encounter.h"
#import "Enemy.h"
#import "CCLabelTTFShadow.h"

@interface EncounterCard ()
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCLabelTTFShadow *titleLabel;
@property (nonatomic, assign) CCLabelTTFShadow *descLabel;
@property (nonatomic, assign) CCLabelTTFShadow *scoreLabel;
@end

@implementation EncounterCard

- (id)initWithLevelNum:(NSInteger)levelNum
{
    if (self = [super init]) {
        _levelNum = levelNum;
        
        self.background = [CCSprite spriteWithSpriteFrameName:@"encounter-card-bg.png"];
        [self.background setColor:ccBLACK];
        [self addChild:self.background];
        
        self.titleLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(480, 50) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.titleLabel setPosition:CGPointMake(0, 60)];
        [self.titleLabel setColor:ccc3(220, 220, 220)];
        [self addChild:self.titleLabel];
        
        self.descLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(450, 150) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS" fontSize:16.0];
        [self.descLabel setPosition:CGPointMake(0, -30)];
        [self.descLabel setColor:ccc3(220, 220, 220)];
        [self addChild:self.descLabel];
        
        self.scoreLabel = [CCLabelTTFShadow labelWithString:@"" dimensions:CGSizeMake(480, 50) hAlignment:kCCTextAlignmentRight fontName:@"TrebuchetMS-Bold" fontSize:20.0];
        self.scoreLabel.visible = NO;
        [self.scoreLabel setPosition:CGPointMake(0, 60)];
        [self.scoreLabel setColor:ccc3(220, 220, 220)];
        [self addChild:self.scoreLabel];
        
        [self reloadCard];
    }
    return self;
}

- (void)reloadCard {
    Encounter *enc = [Encounter encounterForLevel:self.levelNum isMultiplayer:NO];
    
    NSString *encTitle = enc.title;
    NSString *encDesc = enc.info;
    
    NSInteger score = [[PlayerDataManager localPlayer] scoreForLevel:self.levelNum];
    self.scoreLabel.visible = (self.levelNum != 1 && score > 0);
    self.scoreLabel.string = [NSString stringWithFormat:@"High Score: %i", score];
    [self.titleLabel setString:encTitle];
    [self.descLabel setString:encDesc];
}

- (void)setLevelNum:(NSInteger)levelNum
{
    _levelNum = levelNum;
    [self reloadCard];
}
@end
