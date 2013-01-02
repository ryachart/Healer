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
            return @"EASY";
        case 2:
            return @"NORMAL";
        case 3:
            return @"TOUGH";
        case 4:
            return @"PAINFUL";
        case 5:
            return @"BRUTAL";
    }
    return @"";
}

- (id)initWithEncounter:(Encounter*)encounter
{
    if (self = [super init]) {
        self.encounter = encounter;
        
        self.difficultySkulls = [NSMutableArray arrayWithCapacity:5];
        
        self.difficultyWordLabel = [CCLabelTTF labelWithString:[ChallengeRatingStepper difficultyWorldForDifficultyNumber:self.encounter.difficulty] dimensions:CGSizeMake(150, 60) hAlignment:kCCTextAlignmentLeft fontName:@"TrebuchetMS-Bold" fontSize:36.0];
        [self.difficultyWordLabel setPosition:CGPointMake(216.0f, 92.0)];
        [self.difficultyWordLabel setColor:ccYELLOW];
        
        [self addChild:self.difficultyWordLabel];
        
        for (int i = 0; i < 5; i++) {
            CGPoint skullPos = CGPointMake((i * 30) + 45, 56);
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
        
        CCMenu *steppers = [CCMenu menuWithItems:easier, harder, nil];
        [steppers setPosition:CGPointMake(110.0f, 10.0)];
        [steppers alignItemsHorizontally];
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
