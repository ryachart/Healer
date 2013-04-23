//
//  TipsLayer.m
//  Healer
//
//  Created by Ryan Hart on 4/19/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "TipsLayer.h"

@interface TipsLayer ()
@property (nonatomic, retain) NSArray *tipsArray;
@property (nonatomic, retain) NSMutableArray *usedTipsArray;
@property (nonatomic, assign) CCLabelTTF *tipsLabel;
@end

@implementation TipsLayer

- (id)init
{
    if (self = [super init]) {
        NSString *pathToTips = [[NSBundle mainBundle] pathForResource:@"tips" ofType:@"plist"];
        self.tipsArray = [NSArray arrayWithContentsOfFile:pathToTips];
        self.usedTipsArray = [NSMutableArray arrayWithCapacity:self.tipsArray.count];
        
        self.tipsLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(400, 150) hAlignment:kCCTextAlignmentCenter fontName:@"TrebuchetMS-Bold" fontSize:24.0];
        [self.tipsLabel setPosition:CGPointMake(350, 75)];
        [self.tipsLabel setColor:HEALER_BROWN];
        [self addChild:self.tipsLabel];
        
        [self resetUsedTips];
    }
    return self;
}

- (void)resetUsedTips
{
    [self.usedTipsArray removeAllObjects];
    for (int i = 0; i < self.tipsArray.count; i++) {
        [self.usedTipsArray addObject:@NO];
    }
}

- (void)onEnter {
    [super onEnter];
    [self displayRandomTip];
}

- (void)displayRandomTip
{
    NSString *randomTip = [self nextRandomTip];
    NSInteger indexOfTip = [self.tipsArray indexOfObject:randomTip];
    [self.usedTipsArray replaceObjectAtIndex:indexOfTip withObject:@YES];
    [self.tipsLabel setString:[NSString stringWithFormat:@"Tip:\n%@",randomTip]];
    [self.tipsLabel runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1.0 opacity:255],[CCDelayTime actionWithDuration:10.0], [CCFadeTo actionWithDuration:1.0 opacity:0], [CCCallFunc actionWithTarget:self selector:@selector(displayRandomTip)], nil]];
}

- (NSString *)nextRandomTip
{
    NSMutableArray *candidates = [NSMutableArray arrayWithCapacity:self.usedTipsArray.count];
    int i = 0; 
    for (NSNumber *boolNumber in self.usedTipsArray) {
        if (![boolNumber boolValue]) {
            NSString *candidate = [self.tipsArray objectAtIndex:i];
            [candidates addObject:candidate];
        }
        i++;
    }

    if (candidates.count == 0) {
        [self resetUsedTips];
        return [self nextRandomTip];
    }
    
    return [candidates objectAtIndex:arc4random() % candidates.count];
}
@end
