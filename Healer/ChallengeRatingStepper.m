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
@property (nonatomic, retain) NSMutableArray *difficultySkulls;
@end

@implementation ChallengeRatingStepper

- (void)dealloc
{
    [_encounter release];
    [_difficultySkulls release];
    [super dealloc];
}

+ (NSString*)difficultyWorldForDifficultyNumber:(NSInteger)difficulty
{
    switch (difficulty) {
        case 1:
            return @"Easy";
        case 2:
            return @"Normal";
        case 3:
            return @"Tough";
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
        
        self.difficultySkulls = [NSMutableArray arrayWithCapacity:5];
        
        self.difficultyLabel = [CCLabelTTF labelWithString:@"Difficulty:" dimensions:CGSizeMake(150, 30) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [self.difficultyLabel setPosition:CGPointMake(40.0, 100.0)];
        
        self.difficultyWordLabel = [CCLabelTTF labelWithString:[ChallengeRatingStepper difficultyWorldForDifficultyNumber:self.encounter.difficulty] dimensions:CGSizeMake(150, 60) hAlignment:kCCTextAlignmentCenter fontName:@"Arial" fontSize:32.0];
        [self.difficultyWordLabel setPosition:CGPointMake(40.0, 50.0)];
        
        
        [self addChild:self.difficultyLabel];
        [self addChild:self.difficultyWordLabel];
        
        for (int i = 0; i < 5; i++) {
            CGPoint skullPos = CGPointMake((i * 30) - 20, 10);
            CCSprite *skullSprite = [CCSprite spriteWithSpriteFrameName:@"difficulty_skull.png"];
            [skullSprite setPosition:skullPos];
            [self addChild:skullSprite z:100];
            [self.difficultySkulls addObject:skullSprite];
        }
        
        [self configureDifficultySymbols];
        
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

- (void)configureDifficultySymbols {
    for (int i = 0; i < 5; i++){
        CCSprite *currentSkull = [self.difficultySkulls objectAtIndex:i];
        if (self.encounter.difficulty > i) {
            [currentSkull setVisible:YES];
        } else {
            [currentSkull setVisible:NO];
        }
    }
}

- (void)reloadLabels {
    self.difficultyWordLabel.string = [ChallengeRatingStepper difficultyWorldForDifficultyNumber:self.encounter.difficulty];
}

- (void)increaseSelected {
    [self.encounter setDifficulty:self.encounter.difficulty + 1];
    [self reloadLabels];
    [self configureDifficultySymbols];
}

- (void)decreaseSelected {
    [self.encounter setDifficulty:self.encounter.difficulty - 1];
    [self reloadLabels];
    [self configureDifficultySymbols];
}

@end
