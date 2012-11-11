//
//  EncounterCard.m
//  Healer
//
//  Created by Ryan Hart on 10/29/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "EncounterCard.h"
#import "Encounter.h"
#import "Boss.h"

@interface EncounterCard ()
@property (nonatomic, assign) CCSprite *background;
@property (nonatomic, assign) CCLabelTTF *titleLabel;
@property (nonatomic, assign) CCLabelTTF *descLabel;
@end

@implementation EncounterCard

- (id)initWithLevelNum:(NSInteger)levelNum
{
    if (self = [super init]) {
        _levelNum = levelNum;
        
        self.background = [CCSprite spriteWithSpriteFrameName:@"encounter-card-bg.png"];
        [self.background setColor:ccBLACK];
        [self addChild:self.background];
        
        self.titleLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(480, 50) hAlignment:kCCTextAlignmentCenter fontName:@"Marion-Bold" fontSize:28.0];
        [self.titleLabel setPosition:CGPointMake(0, 60)];
        [self.titleLabel setColor:ccc3(220, 220, 220)];
        [self addChild:self.titleLabel];
        
        self.descLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(450, 150) hAlignment:kCCTextAlignmentLeft fontName:@"Marion-Regular" fontSize:16.0];
        [self.descLabel setPosition:CGPointMake(0, -30)];
        [self.descLabel setColor:ccc3(220, 220, 220)];
        [self addChild:self.descLabel];
        
        [self reloadCard];
    }
    return self;
}

- (void)reloadCard {
    Encounter *enc = [Encounter encounterForLevel:self.levelNum isMultiplayer:NO];
    
    NSString *encTitle = enc.boss.title;
    NSString *encDesc = enc.boss.info;
    
    [self.titleLabel setString:encTitle];
    [self.descLabel setString:encDesc];
}

- (void)setLevelNum:(NSInteger)levelNum
{
    _levelNum = levelNum;
    [self reloadCard];
}
@end
