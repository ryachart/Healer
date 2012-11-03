//
//  BossActivationBar.m
//  Healer
//
//  Created by Ryan Hart on 11/2/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "BossActivationBar.h"
#import "Ability.h"


@interface BossActivationBar ()

@property (nonatomic, readwrite, assign) CCLayerColor *backgroundBar;
@property (nonatomic, readwrite, assign) CCLayerColor *activationBar;
@property (nonatomic, readwrite, assign) CCLabelTTF *activationTitleLabel;
@property (nonatomic, readwrite, assign) CCLabelTTF *activationTimeLabel;

@end

@implementation BossActivationBar

- (id)init
{
    if (self = [super init]) {
        self.backgroundBar = [CCLayerColor layerWithColor:ccc4(111, 111, 111, 255) width:200 height:40];
        self.activationBar = [CCLayerColor layerWithColor:ccc4(200, 0, 200, 255) width:200 height:40];
        
        self.activationTimeLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(50, 40) hAlignment:kCCTextAlignmentRight fontName:@"Arial" fontSize:28.0];
        [self.activationTimeLabel setPosition:CGPointMake(150, 0)];
        [self addChild:self.activationTimeLabel];
        
        self.activationTitleLabel = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(140, 40) hAlignment:kCCTextAlignmentLeft fontName:@"Arial" fontSize:28.0];
        [self addChild:self.activationTitleLabel];
    }
    return self;
}

- (void)updateWithAbility:(Ability*)ability
{
    
}

@end
