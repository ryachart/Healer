//
//  ViewDivinityChoiceLayer.m
//  Healer
//
//  Created by Ryan Hart on 11/16/12.
//  Copyright (c) 2012 Ryan Hart Games. All rights reserved.
//

#import "ViewTalentChoiceLayer.h"
#import "TalentTierCard.h"
#import "BasicButton.h"
#import "BackgroundSprite.h"

@interface ViewTalentChoiceLayer ()
@property (nonatomic, assign) BackgroundSprite *alertDialogBackground;
@end

@implementation ViewTalentChoiceLayer

- (id)initWithDivinityChoice:(NSString *)choice inTier:(NSInteger)tier {
    if (self = [super init]) {
        self.scale = 0.0;
        self.alertDialogBackground = [[[BackgroundSprite alloc] initWithAssetName:@"alert-dialog-ipad"] autorelease];
        [self.alertDialogBackground setPosition:CGPointMake(512, 384)];
        [self.alertDialogBackground setAnchorPoint:CGPointMake(.5, .5)];
        [self addChild:self.alertDialogBackground];
        
        TalentTierCard *tierCard = [[[TalentTierCard alloc] initForDivinityTier:tier withSelectedChoice:choice forceUnlocked:YES showsBackground:NO] autorelease];
        [tierCard setAnchorPoint:CGPointMake(.5, .5)];
        [tierCard setPosition:CGPointMake(210, 230)];
        [self.alertDialogBackground addChild:tierCard];
        
        BasicButton *doneButton = [BasicButton basicButtonWithTarget:self andSelector:@selector(complete) andTitle:@"Done"];
        [doneButton setScale:.75];
        CCMenu *menu = [CCMenu menuWithItems:doneButton, nil];
        [menu setPosition:CGPointMake(356, 194)];
        [self.alertDialogBackground addChild:menu];
        
    }
    return self;
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    [self runAction:[CCScaleTo actionWithDuration:.15 scale:1.0]];

}

- (void)notifyDelegateToDismiss
{
    [self.delegate dismissDivinityChoiceLayer:self];
}

- (void)complete {
    [self runAction:[CCSequence actionOne:[CCScaleTo actionWithDuration:.15 scale:0.0] two:[CCCallFunc actionWithTarget:self selector:@selector(notifyDelegateToDismiss)]]];
}
@end
