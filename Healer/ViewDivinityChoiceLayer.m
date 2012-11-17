//
//  ViewDivinityChoiceLayer.m
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ViewDivinityChoiceLayer.h"
#import "DivinityTierCard.h"
#import "BasicButton.h"

@interface ViewDivinityChoiceLayer ()
@property (nonatomic, assign) CCSprite *alertDialogBackground;
@end

@implementation ViewDivinityChoiceLayer

- (id)initWithDivinityChoice:(NSString *)choice inTier:(NSInteger)tier {
    if (self = [super init]) {
        self.scale = 0.0;
        self.alertDialogBackground = [CCSprite spriteWithSpriteFrameName:@"alert-dialog.png"];
        [self.alertDialogBackground setPosition:CGPointMake(512, 384)];
        [self.alertDialogBackground setAnchorPoint:CGPointMake(.5, .5)];
        [self addChild:self.alertDialogBackground];
        
        DivinityTierCard *tierCard = [[[DivinityTierCard alloc] initForDivinityTier:tier withSelectedChoice:choice forceUnlocked:YES showsBackground:NO] autorelease];
        [tierCard setAnchorPoint:CGPointMake(.5, .5)];
        [tierCard setPosition:CGPointMake(195, 210)];
        [self.alertDialogBackground addChild:tierCard];
        
        BasicButton *doneButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(complete) andTitle:@"Done"];
        CCMenu *menu = [CCMenu menuWithItems:doneButton, nil];
        [menu setPosition:CGPointMake(320, 174)];
        [self.alertDialogBackground addChild:menu];
        
    }
    return self;
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [self runAction:[CCScaleTo actionWithDuration:.33 scale:1.0]];

}

- (void)notifyDelegateToDismiss
{
    [self.delegate dismissDivinityChoiceLayer:self];
}

- (void)complete {
    [self runAction:[CCSequence actionOne:[CCScaleTo actionWithDuration:.33 scale:0.0] two:[CCCallFunc actionWithTarget:self selector:@selector(notifyDelegateToDismiss)]]];
}
@end
