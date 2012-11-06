//
//  ChallengeRatingStepper.m
//  Healer
//
//  Created by Ryan Hart on 11/5/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ChallengeRatingStepper.h"
#import "Encounter.h"

#import "BasicButton.h"


@interface ChallengeRatingStepper ()
@property (nonatomic, retain) Encounter *encounter;
@property (nonatomic, assign) CCLabelTTF *difficultyLabel;
@property (nonatomic, assign) CCLabelTTF *difficultyWordLabel;
@property (nonatomic, assign) CCLabelTTF *difficultyRankLabel;
@end

@implementation ChallengeRatingStepper

- (void)dealloc
{
    [_encounter release];
    [super dealloc];
}

+ (NSString*)difficultyWorldForDifficultyNumber:(NSInteger)difficulty
{
    switch (difficulty) {
        case 1:
            return @"Very Easy";
        case 2:
            return @"Easy";
        case 3:
            return @"Normal";
        case 4:
            return @"Painful";
        case 5:
            return @"Brutal";
    }
    return @"";
}

- (id)initWithEncounter:(Encounter*)encounter
{
    if (self = [super init]) {
        self.encounter = encounter;
        
        CCLayerColor *background = [CCLayerColor layerWithColor:ccc4(25, 25, 25, 255) width:200 height:120];
        [background setPosition:CGPointMake(-60, 0.0)];
        [self addChild:background];
        
        self.difficultyLabel = [CCLabelTTF labelWithString:@"Difficulty:" dimensions:CGSizeMake(150, 30) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [self.difficultyLabel setPosition:CGPointMake(40.0, 100.0)];
        
        self.difficultyWordLabel = [CCLabelTTF labelWithString:[ChallengeRatingStepper difficultyWorldForDifficultyNumber:self.encounter.difficulty] dimensions:CGSizeMake(150, 60) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.difficultyWordLabel setPosition:CGPointMake(40.0, 50.0)];
        
        self.difficultyRankLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i/5",self.encounter.difficulty] dimensions:CGSizeMake(150, 24) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:14.0];
        [self.difficultyRankLabel setPosition:CGPointMake(40.0, 20.0)];
        
        [self addChild:self.difficultyLabel];
        [self addChild:self.difficultyWordLabel];
        [self addChild:self.difficultyRankLabel];
        
        BasicButton *harder = [BasicButton basicButtonWithTarget:self andSelector:@selector(increaseSelected) andTitle:@"Harder"];
        [harder setScale:.5];
        BasicButton *easier = [BasicButton basicButtonWithTarget:self andSelector:@selector(decreaseSelected) andTitle:@"Easier"];
        [easier setScale:.5];
        
        CCMenu *steppers = [CCMenu menuWithItems:harder, easier, nil];
        [steppers setPosition:CGPointMake(200.0, 60.0)];
        [steppers alignItemsVertically];
        [self addChild:steppers];
        
    }
    return self;
}

- (void)reloadLabels {
    self.difficultyRankLabel.string = [NSString stringWithFormat:@"%i/5",self.encounter.difficulty];
    self.difficultyWordLabel.string     = [ChallengeRatingStepper difficultyWorldForDifficultyNumber:self.encounter.difficulty];
}

- (void)increaseSelected {
    [self.encounter setDifficulty:self.encounter.difficulty + 1];
    [self reloadLabels];
}

- (void)decreaseSelected {
    [self.encounter setDifficulty:self.encounter.difficulty - 1];
    [self reloadLabels];
}

@end
