//
//  GamePlayPauseLayer.m
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//

#import "GamePlayPauseLayer.h"

@implementation GamePlayPauseLayer
- (id)initWithDelegate:(id)newDelegate {
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]){
        self.delegate = newDelegate;
        
        CCLabelTTF *paused = [CCLabelTTF labelWithString:@"Paused" fontName:@"Marion-Bold" fontSize:64.0];
        [paused setPosition: IS_IPAD ? CGPointMake(512, 670) : CGPointMake(160, SCREEN_HEIGHT - 50)];
        [self addChild:paused];
        
        CCLabelTTF *closeLabel = [CCLabelTTF labelWithString:@"Resume" fontName:@"TrebuchetMS-Bold" fontSize:48.0];
        CCLabelTTF *quitLabel = [CCLabelTTF labelWithString:@"Escape" fontName:@"TrebuchetMS-Bold" fontSize:48.0];
        CCLabelTTF *restartLabel = [CCLabelTTF labelWithString:@"Restart" fontName:@"TrebuchetMS-Bold" fontSize:48.0];
        
        CCMenu *menu = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:closeLabel target:self selector:@selector(close)],
                                            [CCMenuItemLabel itemWithLabel:quitLabel target:self selector:@selector(quit)], nil];
        
        if (IS_IPAD) {
            [menu alignItemsHorizontallyWithPadding:100.0];
        } else {
            [menu alignItemsVerticallyWithPadding:50.0];
        }
        
        [self addChild:menu];
        
        CCMenu *restartMenu = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:restartLabel target:self selector:@selector(restart)], nil];
        [self addChild:restartMenu];
        [restartMenu setPosition: IS_IPAD ? CGPointMake(512, 300) : CGPointMake(160, 100)];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    [self runAction:[CCFadeTo actionWithDuration:.33 opacity:150]];
}

- (void)quit{
    [self.delegate pauseLayerDidQuit];
}


- (void)close{
    [self.delegate pauseLayerDidFinish];
}

- (void)restart
{
    [self.delegate pauseLayerDidRestart];
}
@end
