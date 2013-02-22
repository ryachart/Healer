//
//  GamePlayPauseLayer.m
//  Healer
//
//  Created by Ryan Hart on 3/31/12.
//

#import "GamePlayPauseLayer.h"

@implementation GamePlayPauseLayer
-(id)initWithDelegate:(id)newDelegate{
    if (self = [super initWithColor:ccc4(0, 0, 0, 0)]){
        self.delegate = newDelegate;
        
        CCLabelTTF *paused = [CCLabelTTF labelWithString:@"Paused" fontName:@"Marion-Bold" fontSize:64.0];
        [paused setPosition:CGPointMake(512, 670)];
        [self addChild:paused];
        
        CCLabelTTF *closeLabel = [CCLabelTTF labelWithString:@"Resume" fontName:@"TrebuchetMS-Bold" fontSize:48.0];
        CCLabelTTF *quitLabel = [CCLabelTTF labelWithString:@"Escape" fontName:@"TrebuchetMS-Bold" fontSize:48.0];
        
        CCMenu *menu = [CCMenu menuWithItems:[CCMenuItemLabel itemWithLabel:closeLabel target:self selector:@selector(close)],
                                            [CCMenuItemLabel itemWithLabel:quitLabel target:self selector:@selector(quit)], nil];
        [menu alignItemsHorizontallyWithPadding:100.0];
        [self addChild:menu];
    }
    return self;
}

- (void)onEnter {
    [super onEnter];
    
    [self runAction:[CCFadeTo actionWithDuration:.33 opacity:150]];
}

-(void)quit{
    [self.delegate pauseLayerDidQuit];
}


-(void)close{
    [self.delegate pauseLayerDidFinish];
}

@end
