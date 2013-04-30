//
//  SettingsScene.m
//  Healer
//
//  Created by Ryan Hart on 11/10/12.
//  Copyright (c) 2012 Apple. All rights reserved.
//

#import "SettingsScene.h"
#import "BasicButton.h"
#import "HealerStartScene.h"
#import "BackgroundSprite.h"
#import "PlayerDataManager.h"
#import "SimpleAudioEngine.h"

@interface SettingsScene ()
@property (nonatomic, assign) CCLabelTTF *effectsToggleLabel;
@property (nonatomic, assign) CCLabelTTF *musicToggleLabel;
@property (nonatomic, assign) CCMenuItemToggle *effectsButton;
@property (nonatomic, assign) CCMenuItemToggle *musicButton;
@end

@implementation SettingsScene

- (id)init
{
    if (self = [super init]) {
        [self addChild:[[[BackgroundSprite alloc] initWithJPEGAssetName:@"default-background"] autorelease]];
        
        CCLabelTTF *settingsLabel = [CCLabelTTF labelWithString:@"SETTINGS" fontName:@"TeluguSangamMN-Bold" fontSize:64.0];
        settingsLabel.color = HEALER_BROWN;
        [settingsLabel setPosition:CGPointMake(252, 600)];
        [self addChild:settingsLabel];
        
        BasicButton *resetGame = [BasicButton basicButtonWithTarget:self andSelector:@selector(resetGame) andTitle:@"Erase Data"];
        BasicButton *feedback = [BasicButton basicButtonWithTarget:self andSelector:@selector(feedback) andTitle:@"Feedback"];
        
        CCMenu *settingsMenu = [CCMenu menuWithItems:feedback, resetGame, nil];
        [settingsMenu setPosition:CGPointMake(250, 235)];
        [settingsMenu alignItemsVerticallyWithPadding:20.0];
        [self addChild:settingsMenu];
        
        self.effectsToggleLabel = [CCLabelTTF labelWithString:@"On" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        self.effectsToggleLabel.color = HEALER_BROWN;
        self.effectsToggleLabel.position = CGPointMake(400, 480);
        [self addChild:self.effectsToggleLabel];
        
        self.musicToggleLabel = [CCLabelTTF labelWithString:@"On" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        self.musicToggleLabel.color = HEALER_BROWN;
        self.musicToggleLabel.position = CGPointMake(400, 400);
        [self addChild:self.musicToggleLabel];
        
        CCMenu *backButton = [BasicButton defaultBackButtonWithTarget:self andSelector:@selector(back)];
        [backButton setPosition:CGPointMake(90, [CCDirector sharedDirector].winSize.height * .95)];
        [self addChild:backButton];
        
        CCSprite *enabledEffects = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
        CCSprite *disabledEffects = [CCSprite spriteWithSpriteFrameName:@"divinity_item_tested.png"];
        
        CCSprite *d_enabledEffects = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
        CCSprite *d_disabledEffects = [CCSprite spriteWithSpriteFrameName:@"divinity_item_tested.png"];
        
        CCMenuItemSprite *enabledEffectItem = [CCMenuItemSprite itemWithNormalSprite:enabledEffects selectedSprite:disabledEffects];
        CCMenuItemSprite *disabledEffectItem = [CCMenuItemSprite itemWithNormalSprite:d_disabledEffects selectedSprite:d_enabledEffects];
        
        CCLabelTTF *soundEffectsLabel = [CCLabelTTF labelWithString:@"Sound Effects:" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        soundEffectsLabel.position = CGPointMake(160, 480);
        soundEffectsLabel.color = HEALER_BROWN;
        [self addChild:soundEffectsLabel];
        
        self.effectsButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(toggleEffects) items:enabledEffectItem, disabledEffectItem, nil];
        [self.effectsButton setSelectedIndex:[PlayerDataManager localPlayer].effectsDisabled];
        CCMenu *effectMenu = [CCMenu menuWithItems:self.effectsButton, nil];
        effectMenu.position = CGPointMake(320, 480);
        [self addChild:effectMenu];
        
        CCSprite *enabledMusic = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
        CCSprite *disabledMusic = [CCSprite spriteWithSpriteFrameName:@"divinity_item_tested.png"];
        
        CCSprite *d_enabledMusic = [CCSprite spriteWithSpriteFrameName:@"divinity_item_selected.png"];
        CCSprite *d_disabledMusic = [CCSprite spriteWithSpriteFrameName:@"divinity_item_tested.png"];
        
        CCMenuItemSprite *enabledMusicItem = [CCMenuItemSprite itemWithNormalSprite:enabledMusic selectedSprite:disabledMusic];
        CCMenuItemSprite *disabledMusicItem = [CCMenuItemSprite itemWithNormalSprite:d_disabledMusic selectedSprite:d_enabledMusic];
        
        CCLabelTTF *musicLabel = [CCLabelTTF labelWithString:@"Music:" fontName:@"TrebuchetMS-Bold" fontSize:32.0];
        musicLabel.position = CGPointMake(222, 400);
        musicLabel.color = HEALER_BROWN;
        [self addChild:musicLabel];
        
        self.musicButton = [CCMenuItemToggle itemWithTarget:self selector:@selector(toggleMusic) items:enabledMusicItem, disabledMusicItem, nil];
        [self.musicButton setSelectedIndex:[PlayerDataManager localPlayer].musicDisabled];
        CCMenu *musicMenu = [CCMenu menuWithItems:self.musicButton, nil];
        musicMenu.position = CGPointMake(320, 400);
        [self addChild:musicMenu];
        
        CCLayerColor *divider = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255)];
        divider.color = HEALER_BROWN;
        divider.contentSize = CGSizeMake(1, 768);
        divider.position = CGPointMake(512, 0);
        [self addChild:divider];
        
#pragma Credits
        
        CCLabelTTF *creditsLabel = [CCLabelTTF labelWithString:@"CREDITS" fontName:@"TeluguSangamMN-Bold" fontSize:64.0];
        creditsLabel.color = HEALER_BROWN;
        [creditsLabel setPosition:CGPointMake(772, 600)];
        [self addChild:creditsLabel];
        
        CCLabelTTF *gameDesignProgramming = [CCLabelTTF labelWithString:@"Game Design/Programming\nRyan Hart" fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        gameDesignProgramming.color = HEALER_BROWN;
        [gameDesignProgramming setPosition:CGPointMake(660,480)];
        [self addChild:gameDesignProgramming];
        
        CCLabelTTF *visuals = [CCLabelTTF labelWithString:@"Art Direction/UI Design\nBrad Applebaum" fontName:@"TrebuchetMS-Bold" fontSize:18.0];
        visuals.color = HEALER_BROWN;
        [visuals setPosition:CGPointMake(900,480)];
        [self addChild:visuals];
        
        CCLabelTTF *illustrator = [CCLabelTTF labelWithString:@"Illustration\nLyn Lopez" fontName:@"TrebuchetMS" fontSize:18.0];
        illustrator.color = HEALER_BROWN;
        [illustrator setPosition:CGPointMake(780,390)];
        [self addChild:illustrator];
        
        CCLabelTTF *illustrator2 = [CCLabelTTF labelWithString:@"Illustration\nCraig Simpson" fontName:@"TrebuchetMS" fontSize:18.0];
        illustrator2.color = HEALER_BROWN;
        [illustrator2 setPosition:CGPointMake(780,330)];
        [self addChild:illustrator2];
        
        CCLabelTTF *soundDesign = [CCLabelTTF labelWithString:@"Sound Design\nRJ Temple" fontName:@"TrebuchetMS" fontSize:18.0];
        soundDesign.color = HEALER_BROWN;
        [soundDesign setPosition:CGPointMake(780,270)];
        [self addChild:soundDesign];
        
//        CCLabelTTF *testers = [CCLabelTTF labelWithString:@"Testers\n" fontName:@"TrebuchetMS" fontSize:20.0];
//        testers.color = HEALER_BROWN;
//        [testers setPosition:CGPointMake(780, 220)];
//        [self addChild:testers];
        self.musicToggleLabel.string = [self toggleTextForBool:![PlayerDataManager localPlayer].musicDisabled];
        self.effectsToggleLabel.string = [self toggleTextForBool:![PlayerDataManager localPlayer].effectsDisabled];
    }
    return self;
}

- (NSString *)toggleTextForBool:(BOOL)isOn
{
    return isOn ? @"On" : @"Off";
}

- (void)toggleEffects
{
    [[PlayerDataManager localPlayer] setEffectsDisabled:![PlayerDataManager localPlayer].effectsDisabled];
    self.effectsToggleLabel.string = [self toggleTextForBool:![PlayerDataManager localPlayer].effectsDisabled];
    [SettingsScene configureAudioForUserSettings];
}

- (void)toggleMusic
{
    [[PlayerDataManager localPlayer] setMusicDisabled:![PlayerDataManager localPlayer].musicDisabled];
    self.musicToggleLabel.string = [self toggleTextForBool:![PlayerDataManager localPlayer].musicDisabled];
    [SettingsScene configureAudioForUserSettings];
}

#define DEFAULT_BACKGROUND_VOLUME .5
+ (void)configureAudioForUserSettings
{
    float effectsVolume = ![[PlayerDataManager localPlayer] effectsDisabled];
    float musicVolume = ![[PlayerDataManager localPlayer] musicDisabled];
    
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:musicVolume * DEFAULT_BACKGROUND_VOLUME];
    [[SimpleAudioEngine sharedEngine] setEffectsVolume:effectsVolume];
}

- (void)feedback
{
    MFMailComposeViewController *mailVC = [[[MFMailComposeViewController alloc] init] autorelease];
    [mailVC setSubject:@"Healer Feedback"];
    [mailVC setMailComposeDelegate:self];
    [mailVC setToRecipients:@[@"feedback@healergame.com"]];
    [[CCDirectorIOS sharedDirector] presentModalViewController:mailVC animated:YES];
}

- (void)resetGame
{
    UIAlertView *areYouSure = [[[UIAlertView alloc] initWithTitle:@"Are you Sure?" message:@"Are you sure you want to erase all of your game data and start over again? Your data will not be recoverable." delegate:self cancelButtonTitle:@"No!" otherButtonTitles:@"Yes", nil] autorelease];
    [areYouSure show];
}

- (void)back
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.5 scene:[[[HealerStartScene alloc] init] autorelease]]];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [[PlayerDataManager localPlayer] resetPlayer];
    }
}

#pragma mark - Mail
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [[CCDirectorIOS sharedDirector] dismissModalViewControllerAnimated:YES];
}
@end
