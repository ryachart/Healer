//
//  ModalDialogLayer.m
//  Healer
//
//  Created by Ryan Hart on 9/27/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "ModalDialogLayer.h"
#import "BasicButton.h"

@interface ModalDialogLayer ()
@property (nonatomic, assign) CCLayerColor *darkeningBackground;
@property (nonatomic, assign) CCMenu *dismissDefaultButton;
@end

@implementation ModalDialogLayer

- (id)init
{
    if (self = [super init]){
        self.anchorPoint = CGPointMake(.5,.5);
        self.darkeningBackground = [CCLayerColor layerWithColor:ccc4(25, 25, 25, 0)];
        [self.darkeningBackground setPosition:CGPointMake(-512, -384)];
        [self addChild:self.darkeningBackground];
        
        self.contentSprite = [CCSprite spriteWithSpriteFrameName:@"alert-dialog.png"];
        [self addChild:self.contentSprite];
        [self.contentSprite setScale:.8];
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    if (self = [self init]){
        CCLabelTTF *textLabel = [CCLabelTTF labelWithString:text dimensions:CGSizeMake(self.contentSprite.contentSize.width - 20, self.contentSprite.contentSize.height - 40) hAlignment:UITextAlignmentCenter fontName:@"Arial" fontSize:24.0];
        [textLabel setPosition:CGPointMake(self.contentSprite.contentSize.width / 2, self.contentSprite.contentSize.height / 3 - 20)];
        [self.contentSprite addChild:textLabel];
        
        self.dismissDefaultButton = [CCMenu menuWithItems:[BasicButton basicButtonWithTarget:self andSelector:@selector(dismiss) andTitle:@"Okay"], nil];
        [self.dismissDefaultButton setPosition:CGPointMake(self.contentSprite.contentSize.width / 2, 175)];
        [self.contentSprite addChild:self.dismissDefaultButton];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    [self.dismissDefaultButton setHandlerPriority:kCCMenuHandlerPriority - 1001];
    [[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1000 swallowsTouches:YES];
    [self.darkeningBackground runAction:[CCFadeTo actionWithDuration:.5 opacity:100]];
    [self.contentSprite runAction:[CCSpawn actionOne:[CCFadeIn actionWithDuration:.5] two:[CCScaleTo actionWithDuration:.5 scale:1.0]]];
}

- (void)onExit{
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
    [super onExit];
}

- (void)show {
    self.position = CGPointMake([CCDirector sharedDirector].winSize.width / 2, [CCDirector sharedDirector].winSize.height / 2);
    [[[CCDirector sharedDirector] runningScene] addChild:self z:5000];
}

- (void)dismiss
{
    [self.darkeningBackground runAction:[CCFadeTo actionWithDuration:.25 opacity:0]];
    [self.contentSprite runAction:[CCFadeOut actionWithDuration:.25]];
    [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:.33] two:[CCCallBlockN actionWithBlock:^(CCNode *node){
        [node removeFromParentAndCleanup:YES];
    }]]];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}

@end
